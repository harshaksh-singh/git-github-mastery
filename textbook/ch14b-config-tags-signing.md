# Chapter 14B: Configuration, Aliases, Tags and Signing

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch14b/`. The signing demos generate throwaway SSH keys inside the sandbox; they are marked where they appear, and their keys, signatures and object IDs differ on every run.

## 14B.1 Why this matters

Four questions a CTO can ask in one release week.

1. "Two engineers ran `git pull` on the same diverged branch. One got a merge commit, one got a rebase, the third got an error. Same repository, same Git. Why?"
2. "Half of the commits a contractor pushed to the company repository carry her private email address. She says she set the work address months ago. Who is right?"
3. "The container labelled `v1.2.0` in production does not contain the fix that the tag `v1.2.0` contains on my laptop. Which one is `v1.2.0`?"
4. "A commit on `main` says it was written by our staff engineer. She was on a flight. Can Git tell us who made it?"

The first two are configuration: Git assembles its behavior from several files, the command line and the environment (sections 14B.2 to 14B.7). The third is a tag that was moved after it had been published (sections 14B.8 to 14B.14). The fourth is identity: author and committer are text that the committer supplies, and only a signature ties an object to a key (sections 14B.15 to 14B.18).

One idea runs through all three parts: Git records what it is told. Configuration decides what Git does on *your* machine and is never transferred. A tag is a name that every clone holds separately. A signature is the only statement in an object that somebody else can check.

## 14B.2 Scopes: where a setting comes from, and which value wins

**In one sentence.** A Git setting is a key with one or more values, read from several files plus the command line, and when the same key appears more than once the value read last wins.

**Analogy.** Company policy, team convention, and what your manager tells you this morning: the most specific instruction overrides the general one. The analogy breaks for multi-valued keys, where nothing is overridden: every value from every file counts.

**Precisely.** The manual names five scopes ([git-config](https://git-scm.com/docs/git-config), "SCOPES"), read in this order:

| Scope | Source | Written with | Typical content |
|---|---|---|---|
| `system` | `$(prefix)/etc/gitconfig` | `--system` | defaults an administrator sets for every user of the machine |
| `global` | `$XDG_CONFIG_HOME/git/config`, then `~/.gitconfig` | `--global` | your identity, your editor, your aliases |
| `local` | `.git/config` of the repository | `--local` (the default for writing) | remotes, upstreams, repository-specific overrides |
| `worktree` | `.git/config.worktree` | `--worktree` | settings for one working tree, only if `extensions.worktreeConfig` is set |
| `command` | `git -c <key>=<value>`, and the `GIT_CONFIG_COUNT` family of environment variables | not stored | one invocation |

"Global" means "for this user". `$(prefix)` is the directory Git was installed under, so the Homebrew Git and Apple's Git on your Mac have different system files. Outside the lab, `git var GIT_CONFIG_SYSTEM` prints the path.

**Inside `.git`.** Only `config` and, optionally, `config.worktree` live there. Configuration is not an object and not a ref: it has no history, and no transfer command carries it. A fresh clone has the local configuration that `git clone` wrote and nothing of the configuration of the repository it came from.

**See it.** In the lab the global file is the sandbox's `home/.gitconfig` and the system scope is switched off (`GIT_CONFIG_NOSYSTEM=1`), so your real configuration is never read. In this chapter's demos that directory is also `HOME`, so `~` means `$LAB/ch14b/<demo>/home`. A new repository, and everything Git knows:

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

Three columns: scope, origin, `key=value`. Five lines come from the global file; the six `core.*` lines were written by `git init`. Keys print in lower case because section and variable names are case-insensitive. This command is the first thing to run whenever Git behaves differently on two machines.

Now set one key in two scopes (`git config set` 🟡 CAUTION: it rewrites a file that keeps no history):

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

`get` prints the winning value. `get --all` prints every value in reading order, and the last line is the winner. The command scope beats both files:

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

The `GIT_CONFIG_COUNT` variables are the same scope for scripts that cannot pass `-c` everywhere; `-c` is read last and wins.

The system scope, shown with a stand-in file inside the sandbox (the machine's real system file is not touched):

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

System says `interactive`, global says `true`, local says `false`, and `false` wins. The last two commands show the lab's normal state: no system file, one global file.

Without `GIT_CONFIG_GLOBAL`, the global scope has two files, read in a fixed order:

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

`~/.gitconfig` is read after the XDG file and wins where both set a key. `git config set --global` writes to `~/.gitconfig` unless only the XDG file exists. If you keep your configuration in the XDG location, a stray `~/.gitconfig` created by some tool silently overrides it.

The worktree scope has a trap:

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

Without `extensions.worktreeConfig`, `--worktree` silently writes to `.git/config`. With it, each working tree gets its own file ([Chapter 25](ch25-worktrees.md)).

**Picture.**

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

**The environment sits beside this stack, not inside it.** Several things that look like configuration are decided by environment variables first:

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

`GIT_EDITOR` (set by the lab so that no editor opens) beats `core.editor`, which beats `EDITOR`. `GIT_AUTHOR_NAME` beats `user.name` even when `user.name` is given with `-c`. The orders are documented per variable ([git-var](https://git-scm.com/docs/git-var), [git](https://git-scm.com/docs/git)): `GIT_EDITOR`, `core.editor`, `VISUAL`, `EDITOR`; `GIT_PAGER`, `core.pager`, `PAGER`; `GIT_SSH_COMMAND`, `core.sshCommand`. `git config list` cannot show these overrides. `git var` shows the result. (The demo uses `EDITOR` because Git skips `VISUAL` on a "dumb" terminal, which is what a script or a CI job has: [editor.c](https://github.com/git/git/blob/v2.55.0/editor.c).)

Outside a repository there is no local scope:

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

**Protected configuration.** The system, global and command scopes are "protected": a few security-sensitive keys, `safe.directory` among them, are honored only there. The local file belongs to whoever created the repository directory, which is not always you: a repository unpacked from an archive brings its `.git/config` along ([Chapter 21B](ch21b-repository-security-incident-response.md)).

**In production.** The CTO's first question. Engineer A has `pull.rebase=true` in `~/.gitconfig`. Engineer B has nothing, so a diverged `git pull` stops (Chapter 12, section 12.6). Engineer C's clone has `pull.rebase=false` in `.git/config`, left by an old setup script. One command per machine settles it: `git config get --all --show-scope --show-origin pull.rebase`.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git config set <key> <value>` | unchanged | unchanged | unchanged | unchanged | `.git/config` rewritten | unchanged | unchanged |
| `git config set --global ...` | unchanged | unchanged | unchanged | unchanged | unchanged; `~/.gitconfig` (or the XDG file) rewritten | unchanged | unchanged |

## 14B.3 Reading and writing configuration

**The subcommands.** Since Git 2.46 `git config` has subcommands, and the older option forms are documented as deprecated modes that still work ([git-config](https://git-scm.com/docs/git-config), "DEPRECATED MODES"). Write the new form; read the old one, because scripts and most tutorials still use it.

| Task | Current form (Git 2.46 or later) | Legacy form |
|---|---|---|
| Read one value | `git config get <key>` | `git config <key>`, `git config --get <key>` |
| Read all values | `git config get --all <key>` | `git config --get-all <key>` |
| Search by pattern | `git config get --all --show-names --regexp <regex>` | `git config --get-regexp <regex>` |
| Write | `git config set <key> <value>` | `git config <key> <value>` |
| Add a value | `git config set --append <key> <value>` | `git config --add <key> <value>` |
| Remove | `git config unset <key>` | `git config --unset <key>` |
| List | `git config list` | `git config -l`, `--list` |
| Open in an editor | `git config edit` | `git config -e`, `--edit` |

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

The exit status is part of the interface: 1 from `get` for a key that is not set, 5 from `unset` for a key that does not exist. The subcommands do not exist before Git 2.46, so a script that must run on older installations (Ubuntu 24.04 ships 2.43.0, according to the Phase 0 report) either checks the version or uses the legacy spelling:

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

**The file format.** Sections, optional subsections in double quotes, and `name = value` lines. On the command line a key is `section.name` or `section.subsection.name`: everything between the first and the last dot is the subsection, which is case-sensitive and may contain dots and slashes.

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

`--comment` (Git 2.45) writes the reason next to the value. The last two commands show URL matching: `get --url` returns the value from the subsection whose URL matches best.

**Types.** Git stores text. A type is applied when a value is read:

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

`2g` is an integer with a scale suffix. A path keeps its `~` in the file and is expanded on reading. A bare name with no `=` is boolean true, as are `yes`, `on` and `1`. `--type` on `set` validates before writing; without it Git stores anything and complains only when a command needs the value.

**Multi-valued keys.** Some keys are lists: `remote.<name>.fetch`, `safe.directory`, `credential.helper`, `versionsort.suffix`, `include.path`.

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

Plain `get` prints only the last value of a list. `set` and `unset` refuse a key with several values (status 5) until you say which: `--value=<regex>` selects, `--all` takes everything, `--append` adds.

**Finding keys.**

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

`git help --config` lists every variable this Git knows. Git does not check a key against that list:

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

`pull.rebsae` is stored, reported, and ignored forever; only a key without a section is rejected. Other tools rely on this freedom to keep their settings in Git's files. The cost is that a typing mistake is silent. Lab 5.4 builds a check from `git help --config`.

**Which file does `edit` open?**

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

**A broken file stops everything.**

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

```text
Observed behavior : every Git command in one repository fails with "fatal: bad config line 19
                    in file .git/config", including git config edit and git config list --global.
Git state         : objects, refs and index are intact. One line of .git/config is not valid syntax.
Mechanism         : every command reads the whole configuration before it does anything, and a
                    parse error in a file it must read is fatal.
Root cause        : a hand edit (here a section header without its closing bracket).
Why Git does this : running with half a configuration could mean the wrong identity, the wrong
                    remote or a skipped safety setting; refusing is the conservative choice.
Correct fix       : open the named file at the named line with a text editor, not with Git.
Prevention        : change settings with git config set; after a hand edit run git config list.
```

## 14B.4 Include files and conditional includes: two identities

**In one sentence.** `include.path` reads another file at the point where the line stands, and `includeIf.<condition>.path` does so only when a condition about the current repository is true.

**Analogy.** A footnote that says "insert appendix D here, but only in the edition for the Bengaluru office". The analogy breaks because order matters: text inserted early is overridden by a later line of the including file.

**Precisely.** The conditions in Git 2.55 are `gitdir:<pattern>` and `gitdir/i:<pattern>` (the location of the repository's `.git` directory matches a glob), `onbranch:<pattern>` (the branch that is checked out), and `hasconfig:remote.*.url:<pattern>` (some remote of the repository has a matching URL). In a `gitdir` pattern a leading `~/` is your home directory, a trailing `/` means "everything below", and a pattern that starts with neither `~/`, `./` nor `/` gets `**/` put in front of it (git-config, "Conditional includes").

**See it.** You work for a company and maintain an open-source project. Work repositories live under `~/work`. The global file holds the personal address, and a second file holds the work address:

<!-- snippet: ch14b/includes/02-include-if -->
```text
$ printf '[user]\n\temail = lab.user@corp.example\n' > ~/.gitconfig-work
$ git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'
$ cat ~/.gitconfig
[user]
	name = Lab User
	email = you@example.com
[init]
	defaultBranch = main
[gc]
	reflogExpire = never
	reflogExpireUnreachable = never
[includeIf "gitdir:~/work/"]
	path = ~/.gitconfig-work
```
<!-- /snippet -->

<!-- snippet: ch14b/includes/03-effect -->
```text
$ cd ~/work/inference-gateway
$ git config get --all --show-scope --show-origin user.email
global	file:$LAB/ch14b/includes/home/.gitconfig	you@example.com
global	file:$LAB/ch14b/includes/home/.gitconfig-work	lab.user@corp.example
$ git var GIT_AUTHOR_IDENT
Lab User <lab.user@corp.example> 1788756300 +0530
$ cd ~/oss/evalkit
$ git config get --all --show-scope --show-origin user.email
global	file:$LAB/ch14b/includes/home/.gitconfig	you@example.com
$ git var GIT_AUTHOR_IDENT
Lab User <you@example.com> 1788756480 +0530
```
<!-- /snippet -->

Inside `~/work/inference-gateway` there are two global values, and the second, from the included file, wins. In `~/oss/evalkit` the file is not read. The commits prove it (in this section the identity comes from configuration; the lab library normally pins it through environment variables, which would hide the effect):

<!-- snippet: ch14b/includes/04-commits -->
```text
$ cd ~/work/inference-gateway
$ printf 'timeout_seconds: 30\n' >> config/limits.yaml
$ git commit -q -am "Add request timeout"
$ git log -2 --format='%h  %an <%ae>  %s'
ad95595  Lab User <lab.user@corp.example>  Add request timeout
eb112a5  Lab User <you@example.com>  Add rate limits
```
<!-- /snippet -->

**Picture.**

```text
  ~/.gitconfig                                    ~/.gitconfig-work
  +-----------------------------------+           +-----------------------------------+
  | [user]                            |           | [user]                            |
  |     name  = Lab User              |           |     email = lab.user@corp.example |
  |     email = you@example.com       |           +-----------------------------------+
  | [includeIf "gitdir:~/work/"]      |   read here, and only if the repository's
  |     path = ~/.gitconfig-work  ----+-->  .git directory is somewhere under ~/work/
  +-----------------------------------+

  reading order in ~/work/inference-gateway:  you@example.com, then lab.user@corp.example (wins)
  reading order in ~/oss/evalkit:             you@example.com (wins)
```

**Five ways the rule silently does not apply.** Each one produces commits with the wrong address and no message.

*The trailing slash.* `gitdir:~/work` matches only a repository whose `.git` directory *is* `~/work`:

<!-- snippet: ch14b/includes/06-no-slash -->
```text
$ git config unset --global 'includeIf.gitdir:~/work/.path'
$ git config set --global 'includeIf.gitdir:~/work.path' '~/.gitconfig-work'
$ git config get user.email
you@example.com
$ git config unset --global 'includeIf.gitdir:~/work.path'
$ git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'
$ git config get user.email
lab.user@corp.example
```
<!-- /snippet -->

*Order.* The include is read where it stands. If `[user]` comes after it in the including file, the general value is read last and wins:

<!-- snippet: ch14b/includes/07-order -->
```text
# The same two sections in the other order: the conditional include first, [user] after it.
$ cp ~/.gitconfig ~/.gitconfig.good
$ printf '[includeIf "gitdir:~/work/"]\n\tpath = ~/.gitconfig-work\n[user]\n\tname = Lab User\n\temail = you@example.com\n[init]\n\tdefaultBranch = main\n' > ~/.gitconfig
$ git config get --all --show-origin user.email
file:$LAB/ch14b/includes/home/.gitconfig-work	lab.user@corp.example
file:$LAB/ch14b/includes/home/.gitconfig	you@example.com
$ git config get user.email
you@example.com
$ mv ~/.gitconfig.good ~/.gitconfig
$ git config get user.email
lab.user@corp.example
```
<!-- /snippet -->

Keep conditional includes at the end of the file.

*Not in a repository.* `gitdir` needs a `.git` directory. In `~/work` itself there is none:

<!-- snippet: ch14b/includes/08-not-in-a-repository -->
```text
$ cd ~/work
$ git config get user.email
you@example.com
$ git init -q rag-indexer
$ git -C rag-indexer config get user.email
lab.user@corp.example
```
<!-- /snippet -->

*A missing file.* An include that names a file that does not exist is skipped without an error:

<!-- snippet: ch14b/includes/09-missing-file -->
```text
$ git config set --global 'includeIf.gitdir:~/clients/.path' '~/.gitconfig-clients'
$ git init -q ~/clients/acme-chatbot
$ ls ~/.gitconfig-clients
ls: $LAB/ch14b/includes/home/.gitconfig-clients: No such file or directory
[exit status: 1]
$ git -C ~/clients/acme-chatbot config get --show-origin user.email
file:$LAB/ch14b/includes/home/.gitconfig	you@example.com
```
<!-- /snippet -->

*Asking the wrong question.* A scope option switches include processing off, so the usual diagnostic lies unless you add `--includes`:

<!-- snippet: ch14b/includes/05-includes-flag -->
```text
# Asking one scope by name switches include processing off unless you ask for it.
$ git config get --global user.email
you@example.com
$ git config get --global --includes user.email
lab.user@corp.example
$ git config list --global --show-origin | grep user
file:$LAB/ch14b/includes/home/.gitconfig	user.name=Lab User
file:$LAB/ch14b/includes/home/.gitconfig	user.email=you@example.com
$ git config list --global --includes --show-origin | grep user
file:$LAB/ch14b/includes/home/.gitconfig	user.name=Lab User
file:$LAB/ch14b/includes/home/.gitconfig	user.email=you@example.com
file:$LAB/ch14b/includes/home/.gitconfig-work	user.email=lab.user@corp.example
```
<!-- /snippet -->

**By remote, not by directory.** `hasconfig:remote.*.url:` chooses by where the repository is pushed, wherever it lies on disk:

<!-- snippet: ch14b/includes/10-hasconfig -->
```text
$ printf '[user]\n\temail = lab.user@corp.example\n' > ~/.gitconfig-corp-remote
$ git config set --global 'includeIf.hasconfig:remote.*.url:git@git.corp.example:platform/**.path' '~/.gitconfig-corp-remote'
$ git init -q ~/tmp/prompt-library
$ cd ~/tmp/prompt-library
$ git config get --show-origin user.email
file:$LAB/ch14b/includes/home/.gitconfig	you@example.com
$ git remote add origin git@git.corp.example:platform/prompt-library.git
$ git config get --show-origin user.email
file:$LAB/ch14b/includes/home/.gitconfig-corp-remote	lab.user@corp.example
```
<!-- /snippet -->

The identity changed the moment the remote was added. Files included this way may not themselves define remote URLs.

**A team file, opted into.** Git never reads configuration from the files it tracks; if it did, cloning a repository would let its author set your pager, your SSH command and your hooks. A team that wants shared settings commits a file and asks each member to include it once:

<!-- snippet: ch14b/includes/11-team-file -->
```text
$ cd ~/work/inference-gateway
$ printf '[merge]\n\tconflictStyle = zdiff3\n[rebase]\n\tupdateRefs = true\n' > .gitconfig-team
$ git config get merge.conflictStyle
[exit status: 1]
$ git config set include.path ../.gitconfig-team
$ git config get --show-scope --show-origin merge.conflictStyle
local	file:.git/../.gitconfig-team	zdiff3
$ git config list --local --includes --show-origin | tail -3
file:.git/config	include.path=../.gitconfig-team
file:.git/../.gitconfig-team	merge.conflictstyle=zdiff3
file:.git/../.gitconfig-team	rebase.updaterefs=true
```
<!-- /snippet -->

A relative `include.path` is resolved against the file that contains it, here `.git/config`. Review changes to such a file like code: it can define an alias that runs a shell command.

**In production.** The CTO's second question. The contractor did set her work address, in `~/.gitconfig-work`, with `[includeIf "gitdir:~/work"]`. The pattern has no trailing slash, so it never matched. Diagnose with `git config get --all --show-origin user.email` inside the repository; fix the pattern; set `user.useConfigOnly=true` and remove the global default address, so that a repository outside both directories refuses to commit (Chapter 6, section 6.13). Published commits keep the address they have.

## 14B.5 The settings to decide deliberately

Most settings never need your attention. The twenty below, in nineteen rows because `user.name` and `user.email` share one, change what everyday commands do, so "I never set it" is also a decision, made by the default. The mechanics are in the chapter named; the facts are from [git-config](https://git-scm.com/docs/git-config) unless a source is given.

| Setting | What it does | Why it matters | Downside | Optional? | Personal or team |
|---|---|---|---|---|---|
| `user.name`, `user.email` | Identity copied into every commit and annotated tag | Attribution; GitHub links commits to accounts by this email (Chapter 6) | Unchecked text; the wrong scope gives the wrong identity for years | Required | Personal, one per context (section 14B.4) |
| `init.defaultBranch` | Name of the first branch in `git init` | Unconfigured Git 2.55 creates `master`; Git 3.0 will create `main` (Phase 0 report) | None found; new repositories only | Recommended | Personal, following the team's name |
| `pull.rebase` | How `git pull` integrates: `false` merge, `true` rebase, `merges`, `interactive` | With nothing set, a diverged pull is fatal (Chapter 12, section 12.6) | `true` gives unpublished commits new IDs and flattens local merges | Decide one way | Personal; a team convention keeps history uniform |
| `pull.ff` | `only`: pull refuses anything but a fast-forward | You integrate deliberately | In configuration `only` wins over `pull.rebase` (Chapter 12), so a diverged pull needs a flag | Optional | Personal |
| `push.default` | What a bare `git push` updates; `simple` since Git 2.0 | `matching` and `upstream` can update a branch you did not mean (Chapter 12, section 12.5) | `simple` refuses when the upstream has another name | Leave the default | Personal |
| `push.autoSetupRemote` | The first push of a branch sets its upstream (Git 2.37) | No "has no upstream branch" stop | A mistyped branch name is published at once | Optional | Personal |
| `fetch.prune` | Fetch deletes remote-tracking branches whose branch is gone | `git branch -r` stays true (Chapter 12, section 12.11) | That ref may have been your last name for those commits | Optional | Personal |
| `merge.conflictStyle` | `merge` (default), `diff3`, `zdiff3` (Git 2.35): adds the common ancestor to a conflict | You see what both sides changed *from* (Chapter 8) | Longer conflict regions; a third marker | Recommended | Personal |
| `rebase.autoSquash` | Places `fixup!`, `squash!` and `amend!` commits in an interactive rebase | Makes fixup commits routine (Chapter 9) | A title that starts with those words by accident is moved | Optional | Personal |
| `rebase.autoStash` | Stashes before a rebase, applies after | Rebase with a dirty working tree | The final apply can conflict (manual) | Optional | Personal |
| `rebase.updateRefs` | Branches pointing into the rebased range move with it (Git 2.38) | Stacked branches stay stacked (Chapter 9) | Moves branches you did not name | Optional | Personal |
| `rerere.enabled` | Records conflict resolutions and replays them | Repeated rebases of a long branch ([Chapter 14C](ch14c-stash-rerere-attributes-hooks.md)) | A wrong resolution is replayed too | Optional | Personal |
| `diff.algorithm` | `myers` (default), `minimal`, `patience`, `histogram` | Readability when code moves (below) | Your diff differs from a colleague's | Optional | Personal |
| `diff.colorMoved` | Colors moved lines differently | Review of refactorings | Terminal only | Optional | Personal |
| `core.editor` | Editor for messages and todo lists, unless `GIT_EDITOR` is set | A graphical editor needs its wait option, such as `code --wait` ([GitHub Docs](https://docs.github.com/en/get-started/git-basics/associating-text-editors-with-git)) | None, once tested | Recommended | Personal |
| `core.autocrlf` | Per-user line-ending conversion | A convenience on Windows; not deprecated (Phase 0 report) | Normalizes for you only; the repository-wide tool is `.gitattributes` (Chapter 14C) | Optional; unset on macOS | Team decides through attributes |
| `core.excludesFile` | Personal ignore file; default `$XDG_CONFIG_HOME/git/ignore` | Editor and OS files stay out of project `.gitignore` files (Chapter 4) | A colleague without it commits what you ignore | Optional | Personal |
| `commit.gpgSign` | Signs every commit | Evidence that a key holder made the commit (section 14B.16) | Every commit fails when the key is unavailable | Optional, unless a rule requires signatures | Personal setting, team policy |
| `help.autocorrect` | A mistyped command: show the guess (default), `prompt`, `never`, `immediate`, or a delay | Saves retyping | `immediate` runs a guess; since Git 2.49 the value `1` means `immediate` ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.49.0.adoc)) | Optional | Personal |

Three of these are shown here because no other chapter shows them.

**`init.defaultBranch`.** `git var GIT_DEFAULT_BRANCH` answers "what would `git init` call the first branch", with and without the lab's global file:

<!-- snippet: ch14b/settings/01-default-branch -->
```text
$ git var GIT_DEFAULT_BRANCH
main
$ git config get --show-origin init.defaultBranch
file:$LAB/ch14b/settings/home/.gitconfig	main
# The same question with no global file at all, which is how unconfigured Git 2.55 answers:
$ GIT_CONFIG_GLOBAL=/dev/null git var GIT_DEFAULT_BRANCH
master
```
<!-- /snippet -->

**`help.autocorrect`.**

<!-- snippet: ch14b/settings/02-autocorrect -->
```text
$ git stauts -sb
git: 'stauts' is not a git command. See 'git --help'.

The most similar command is
	status
[exit status: 1]
$ git -c help.autocorrect=never stauts -sb
git: 'stauts' is not a git command. See 'git --help'.
[exit status: 1]
$ git -c help.autocorrect=immediate stauts -sb
WARNING: You called a Git command named 'stauts', which does not exist.
Continuing under the assumption that you meant 'status'.
## main
 M gateway/retry.py
[exit status: 0]
```
<!-- /snippet -->

`immediate` ran the guess. With a typo that resolves to a destructive command, it would have run that.

**`diff.algorithm`.** A function was moved to the top of a file and edited. The default algorithm pairs lines of the two functions with each other:

<!-- snippet: ch14b/settings/03-diff-myers -->
```text
$ git diff --stat
 gateway/retry.py | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)
$ git diff | tail -n +5
@@ -1,16 +1,16 @@
-def call_small(prompt):
-    for attempt in range(3):
+def call_large(prompt):
+    for attempt in range(5):
         try:
-            return small.complete(prompt)
+            return large.complete(prompt)
         except Timeout:
-            continue
-    raise Unavailable("small")
+            backoff(attempt)
+    raise Unavailable("large")
 
 
-def call_large(prompt):
+def call_small(prompt):
     for attempt in range(3):
         try:
-            return large.complete(prompt)
+            return small.complete(prompt)
         except Timeout:
             continue
-    raise Unavailable("large")
+    raise Unavailable("small")
```
<!-- /snippet -->

<!-- snippet: ch14b/settings/04-diff-histogram -->
```text
$ git config set diff.algorithm histogram
$ git diff --stat
 gateway/retry.py | 18 +++++++++---------
 1 file changed, 9 insertions(+), 9 deletions(-)
$ git diff | tail -n +5
@@ -1,3 +1,12 @@
+def call_large(prompt):
+    for attempt in range(5):
+        try:
+            return large.complete(prompt)
+        except Timeout:
+            backoff(attempt)
+    raise Unavailable("large")
+
+
 def call_small(prompt):
     for attempt in range(3):
         try:
@@ -5,12 +14,3 @@ def call_small(prompt):
         except Timeout:
             continue
     raise Unavailable("small")
-
-
-def call_large(prompt):
-    for attempt in range(3):
-        try:
-            return large.complete(prompt)
-        except Timeout:
-            continue
-    raise Unavailable("large")
```
<!-- /snippet -->

Both diffs are correct. `histogram` reports one block added and one removed, which is what happened. The setting changes what you see, never what is stored (Chapter 2).

**A deliberate file.** Lab 5.4 builds a global file one decision at a time. One defensible result, with the reason beside each line:

<!-- snippet: ch14b/lab-05-4-deliberate-config/03-the-file -->
```text
$ cat ~/.gitconfig
[user]
	name = Lab User
	email = you@example.com
	useConfigOnly = true # refuse to guess an identity
[init]
	defaultBranch = main
[gc]
	reflogExpire = never
	reflogExpireUnreachable = never
[pull]
	ff = only # never integrate by accident
[push]
	autoSetupRemote = true # first push sets the upstream
[fetch]
	prune = true # forget branches deleted on the server
[merge]
	conflictStyle = zdiff3 # show the common ancestor in conflicts
[rebase]
	autoSquash = true # fixup! commits find their place
	updateRefs = true # stacked branches move together
[rerere]
	enabled = true # remember conflict resolutions
[diff]
	algorithm = histogram # moved code reads as a move
	colorMoved = default
[help]
	autocorrect = prompt # show the suggestion, run nothing
[core]
	excludesFile = ~/.config/git/ignore
```
<!-- /snippet -->

The `[gc]` section belongs to the lab (Chapter 1, section 1.7); do not copy it.

**Credential helpers, in one paragraph.** `credential.helper` names a program that stores and returns the username and token for HTTPS remotes; `credential.<url>.username` fixes a username per host ([gitcredentials](https://git-scm.com/docs/gitcredentials)). `git help -a | grep credential-` lists the installed helpers. Which one to use, and why a token never belongs in a remote URL, is [Chapter 16](ch16-authentication.md).

**In production.** A platform team runs a script of `git config set --global` lines on every laptop. Six months later nobody remembers why `pull.rebase` is `true`. Two things prevent that: a comment on each line, and a split between the few settings a team must agree on (the default branch name, line-ending attributes, whether signatures are required) and everything else, which stays personal.

## 14B.6 Aliases

**In one sentence.** An alias is a configuration value under `alias.<name>` that Git substitutes for `<name>` when it is the first word of a command line, appending any further arguments.

**Analogy.** A speed-dial key. The analogy breaks at the arguments: whatever you type after the alias is added to the end of the expansion.

**Precisely.** If the value starts with `!`, it is handed to the shell and run from the top-level directory of the repository. Otherwise it is a Git command line, split on spaces with shell-like quoting. An alias cannot replace an existing command. The first word of the expansion may be an option to `git` itself, such as `-c <key>=<value>` ([git-config](https://git-scm.com/docs/git-config), `alias.*`).

**See it.** Five aliases that earn their place:

<!-- snippet: ch14b/aliases/01-define -->
```text
$ git config set --global alias.st 'status -sb'
$ git config set --global alias.lg 'log --graph --decorate --oneline --all'
$ git config set --global alias.last 'log -1 --stat HEAD'
$ git config set --global alias.unstage 'restore --staged --'
$ git config set --global alias.amend 'commit --amend --no-edit'
$ git config get --all --show-names --regexp "^alias\."
alias.st status -sb
alias.lg log --graph --decorate --oneline --all
alias.last log -1 --stat HEAD
alias.unstage restore --staged --
alias.amend commit --amend --no-edit
```
<!-- /snippet -->

<!-- snippet: ch14b/aliases/02-st-lg-last -->
```text
$ git st
## main
$ git lg
* 1adfaa7 (HEAD -> main) Raise the rate limit
| * f29324a (feature/fallback-route) Add fallback route
|/  
* eb112a5 Add rate limits
* 516c4c3 Add model router
* 37da450 Add README
$ git last
commit 1adfaa7ec5b01b116b6d926ce544561f6b29583d
Author: Lab User <you@example.com>
Date:   Mon Sep 7 10:09:00 2026 +0530

    Raise the rate limit

 config/limits.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

- `st` is `status -sb`: the short format plus the branch line (Chapter 4).
- `lg` draws every ref as a graph, one line per commit: the fourth command of Chapter 1's diagnosis ritual, in two letters.
- `last` shows the newest commit with the files it touched.

<!-- snippet: ch14b/aliases/03-unstage -->
```text
$ printf 'burst: 20\n' >> config/limits.yaml
$ printf 'scratch\n' > notes.txt
$ git add .
$ git st
## main
M  config/limits.yaml
A  notes.txt
$ git unstage notes.txt
$ git st
## main
M  config/limits.yaml
?? notes.txt
```
<!-- /snippet -->

`unstage` is `restore --staged --`. The trailing `--` makes everything after it a path. Older aliases with this name say `reset HEAD --`; the effect on the index is the same (Chapter 5).

<!-- snippet: ch14b/aliases/04-amend -->
```text
$ git log -1 --format="%h %s"
1adfaa7 Raise the rate limit
$ git amend
[main e1bef49] Raise the rate limit
 Date: Mon Sep 7 10:09:00 2026 +0530
 1 file changed, 2 insertions(+), 1 deletion(-)
$ git log -1 --format="%h %s"
e1bef49 Raise the rate limit
$ git show --stat --format="%h %s" HEAD
e1bef49 Raise the rate limit

 config/limits.yaml | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)
$ git reflog -2
e1bef49 HEAD@{0}: commit (amend): Raise the rate limit
1adfaa7 HEAD@{1}: commit: Raise the rate limit
```
<!-- /snippet -->

`amend` 🟡 CAUTION is `commit --amend --no-edit`: it replaces the tip commit with one that includes whatever is staged. The old commit is one reflog entry away, and everything Chapter 6 says about amending published commits applies.

**What Git runs.** `GIT_TRACE=1` prints the expansion (the commands here cut the time stamp off each trace line):

<!-- snippet: ch14b/aliases/05-trace -->
```text
$ GIT_TRACE=1 git st 2>&1 | grep -E -o '(alias expansion|built-in): .*'
alias expansion: st => status -sb
built-in: git status -sb
$ GIT_TRACE=1 git lg -1 2>&1 | grep -E -o '(alias expansion|built-in): .*'
alias expansion: lg => log --graph --decorate --oneline --all
built-in: git log --graph --decorate --oneline --all -1
```
<!-- /snippet -->

**Arguments are appended.** That is convenient for `lg -2`. It is a trap for `last`:

<!-- snippet: ch14b/aliases/06-arguments -->
```text
# Arguments after the alias name are appended to the expansion.
$ git lg -2
* e1bef49 (HEAD -> main) Raise the rate limit
| * f29324a (feature/fallback-route) Add fallback route
|/  
$ git last --format="%h %s" feature/fallback-route
e1bef49 Raise the rate limit

 config/limits.yaml | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)
$ GIT_TRACE=1 git last --format='%h %s' feature/fallback-route 2>&1 | grep -E -o 'built-in: .*'
built-in: git log -1 --stat HEAD '--format=%h %s' feature/fallback-route
$ git config set --global alias.last 'log -1 --stat'
$ git last --format="%h %s" feature/fallback-route
f29324a Add fallback route

 gateway/router.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

The alias contained `HEAD`, so the command became `git log -1 --stat HEAD ... feature/fallback-route`: the newest commit reachable from either, which is the tip of `main`. Without the hard-coded `HEAD` the alias shows the last commit of whatever you name.

**Shell aliases.** A value that starts with `!` is a shell command:

<!-- snippet: ch14b/aliases/07-shell-alias -->
```text
$ git config set --global alias.root '!pwd'
$ cd gateway
$ git root
$LAB/ch14b/aliases/home/work/inference-gateway
$ git config set --global alias.where '!echo "prefix=$GIT_PREFIX top=$(pwd)"'
$ git where
prefix=gateway/ top=$LAB/ch14b/aliases/home/work/inference-gateway
$ cd ..
```
<!-- /snippet -->

It ran in the top-level directory although you were in `gateway/`; `GIT_PREFIX` holds the directory you came from. The second trap is again the arguments:

<!-- snippet: ch14b/aliases/08-shell-alias-arguments -->
```text
$ git config set --global alias.tracked '!git ls-tree -r --name-only $1 | head -2'
$ git tracked HEAD
head: HEAD: No such file or directory
[exit status: 1]
$ GIT_TRACE=1 git tracked HEAD 2>&1 | grep -o 'start_command: .*'
start_command: /bin/sh -c 'git ls-tree -r --name-only $1 | head -2 "$@"' 'git ls-tree -r --name-only $1 | head -2' HEAD
$ git config set --global alias.tracked '!f() { git ls-tree -r --name-only "${1:-HEAD}" | head -2; }; f'
$ git tracked HEAD
README.md
config/limits.yaml
$ git tracked feature/fallback-route
README.md
config/limits.yaml
```
<!-- /snippet -->

Git runs `sh -c '<alias> "$@"'`: the arguments are available as `$1` and are *also* appended, here to `head`. The manual's remedy is a function that consumes them: `!f() { ...; }; f`.

**What an alias cannot do.**

<!-- snippet: ch14b/aliases/09-no-override -->
```text
$ git config set --global alias.status 'status -sb'
$ git status
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	notes.txt

nothing added to commit but untracked files present (use "git add" to track)
$ GIT_TRACE=1 git status 2>&1 | grep -E -o '(alias expansion|built-in): .*'
built-in: git status
$ git config unset --global alias.status
```
<!-- /snippet -->

`alias.status` is ignored: built-in commands win. Never use aliases in scripts, hooks or CI: they exist in your configuration only.

<!-- snippet: ch14b/aliases/10-file -->
```text
$ sed -n "/^\[alias\]/,\$p" ~/.gitconfig
[alias]
	st = status -sb
	lg = log --graph --decorate --oneline --all
	last = log -1 --stat
	unstage = restore --staged --
	amend = commit --amend --no-edit
	root = !pwd
	where = !echo \"prefix=$GIT_PREFIX top=$(pwd)\"
	tracked = "!f() { git ls-tree -r --name-only \"${1:-HEAD}\" | head -2; }; f"
```
<!-- /snippet -->

The Git 2.55 manual also documents a subsection form, `[alias "<name>"]` with a `command` key, for names that contain characters outside ASCII letters, digits and dashes; it works on 2.55.0.

> **Unverified.** Which release introduced the `[alias "<name>"] command = ...` form was not checked; older installations may not understand it.

**In production.** `pushf = push --force-with-lease --force-if-includes` is the alias most worth having: the safe form is long enough that people type `--force` instead (Chapter 12, section 12.8). The alias most worth avoiding is a `!` alias pasted from a web page: a shell command that runs with your permissions.

## 14B.7 Environment variables for diagnosis

Configuration says what Git should do. These variables make Git say what it is doing.

| Variable | Shows | Use it when |
|---|---|---|
| `GIT_TRACE=1` | alias expansion, built-in and external commands that are started | "what did that command actually run?" |
| `GIT_TRACE_SETUP=1` | the `.git` directory, the working tree, the current directory and prefix Git settled on | Git picks up the wrong repository, or none |
| `GIT_TRACE_PACKET=1` | the protocol conversation with a remote | fetch and push puzzles (Chapter 12, section 12.13) |
| `GIT_TRACE_CURL=1`, `GIT_CURL_VERBOSE=1` | the HTTP exchange: requests, response codes, headers | HTTPS authentication and proxy failures ([Chapter 16](ch16-authentication.md)) |
| `GIT_SSH_COMMAND='ssh -v ...'` | replaces the `ssh` program and its options for this command | SSH picks the wrong key, or you need `ssh -v` output |
| `GIT_TRACE2_PERF=1` | timings of regions inside a command | "why is `git status` slow?" ([Chapter 26](ch26-performance.md)) |

A value of `1`, `2` or `true` writes to standard error; an absolute path appends to that file ([git](https://git-scm.com/docs/git), "Environment Variables").

<!-- snippet: ch14b/diagnose-env/01-trace -->
```text
$ GIT_TRACE=1 git st 2>&1 | grep -E -o '(trace: (exec|alias expansion|built-in)|##).*'
trace: exec: git-st
trace: alias expansion: st => status -sb
trace: exec: git status -sb
trace: built-in: git status -sb
## main
```
<!-- /snippet -->

<!-- snippet: ch14b/diagnose-env/02-trace-setup -->
```text
$ cd gateway
$ GIT_TRACE_SETUP=1 git st 2>&1 | grep -o 'setup: .*' | grep -v chdir
setup: git_dir: .git
setup: git_common_dir: .git
setup: worktree: $LAB/ch14b/diagnose-env/home/work/inference-gateway
setup: cwd: $LAB/ch14b/diagnose-env/home/work/inference-gateway
setup: prefix: gateway/
$ cd ..
```
<!-- /snippet -->

When Git "does not see" a repository, or sees a parent directory's repository instead of yours, these lines say which.

`GIT_SSH_COMMAND`, shown without a network: a stand-in script named `ssh` prints its arguments and exits.

<!-- snippet: ch14b/diagnose-env/04-ssh-command -->
```text
# ~/lab-bin/ssh is a stand-in that prints its arguments and exits. No connection is made.
$ git remote add origin git@git.corp.example:platform/inference-gateway.git
$ GIT_SSH_COMMAND='~/lab-bin/ssh -i ~/.ssh/id_ed25519_work -o IdentitiesOnly=yes' git fetch origin
ssh was asked to run: -i $LAB/ch14b/diagnose-env/home/.ssh/id_ed25519_work -o IdentitiesOnly=yes -o SendEnv=GIT_PROTOCOL git@git.corp.example git-upload-pack 'platform/inference-gateway.git'
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
[exit status: 128]
```
<!-- /snippet -->

Git appended its own arguments (the host and the remote command `git-upload-pack '<path>'`) to yours. With the real `ssh`, `GIT_SSH_COMMAND='ssh -v' git fetch` shows which keys are offered. `core.sshCommand` does the same permanently, and the variable overrides it:

<!-- snippet: ch14b/diagnose-env/05-ssh-config -->
```text
$ git config set core.sshCommand '~/lab-bin/ssh -i ~/.ssh/id_ed25519_work'
$ git ls-remote origin
ssh was asked to run: -i $LAB/ch14b/diagnose-env/home/.ssh/id_ed25519_work -o SendEnv=GIT_PROTOCOL git@git.corp.example git-upload-pack 'platform/inference-gateway.git'
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
[exit status: 128]
$ GIT_SSH_COMMAND='~/lab-bin/ssh -v' git ls-remote origin
ssh was asked to run: -v -o SendEnv=GIT_PROTOCOL git@git.corp.example git-upload-pack 'platform/inference-gateway.git'
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
[exit status: 128]
```
<!-- /snippet -->

The HTTP variables need a server, so they are not run here:

```bash
GIT_TRACE_CURL=1 git ls-remote https://github.com/<owner>/<repo>.git
GIT_CURL_VERBOSE=1 git ls-remote https://github.com/<owner>/<repo>.git
```

> **Version note.** Older behavior: tutorials name `GIT_CURL_VERBOSE` as the HTTP debugging switch. Current behavior: the Git 2.55 manual documents `GIT_TRACE_CURL` and `GIT_TRACE_CURL_NO_DATA`; `GIT_CURL_VERBOSE` is still read by the HTTP code, which treats it as a curl trace without payload data ([http.c at 2.55.0](https://github.com/git/git/blob/v2.55.0/http.c)). Since: not established. Recommended: `GIT_TRACE_CURL=1`, and keep `GIT_TRACE_REDACT` at its default so that `Authorization` headers stay out of the output you paste into a ticket.

**In production.** The first reply to "Git does something strange on the build machine" is two commands run there: `git config list --show-scope --show-origin`, and the failing command with `GIT_TRACE=1`.

## 14B.8 Tags: three kinds, two mechanisms

**In one sentence.** A tag is a ref under `refs/tags/` that is not expected to move; a lightweight tag points straight at a commit, and an annotated tag points at a tag object that names the commit and records who tagged it, when and why.

**Analogy.** A lightweight tag is a sticky note on a page of the ledger. An annotated tag is a certificate that cites the page number and is filed in the ledger with a page number of its own. The analogy breaks because nobody certifies anything unless the tag is also signed.

**Precisely.** Chapter 7 (section 7.11) introduced the lightweight tag as a ref. The annotated tag adds the fourth object type of Chapter 3. A tag object has four header lines and a message ([git-tag](https://git-scm.com/docs/git-tag), [gitformat-signature](https://git-scm.com/docs/gitformat-signature)):

| Field | Content |
|---|---|
| `object` | the ID of the object being tagged |
| `type` | its type: almost always `commit`, but `tree`, `blob` and `tag` are legal |
| `tag` | the tag's name, repeated inside the object |
| `tagger` | name, email, time and offset of the person who created the tag |
| message | free text; in a signed tag the signature block is appended to it |

A *signed* tag is an annotated tag whose text ends in a signature (section 14B.16). So there are three kinds and two mechanisms: a bare ref, or a ref plus an object.

**See it.** A lightweight tag creates no object:

<!-- snippet: ch14b/tag-kinds/01-lightweight -->
```text
$ git log --oneline
eb112a5 Add rate limits
516c4c3 Add model router
37da450 Add README
$ git tag staging-2026-09-07
$ cat .git/refs/tags/staging-2026-09-07
eb112a5c44b0b2092c4ef2cae6e75b16da000f73
$ git cat-file -t staging-2026-09-07
commit
$ git count-objects | cut -d, -f1
11 objects
```
<!-- /snippet -->

An annotated tag (`git tag -a` 🟢 SAFE) creates one:

<!-- snippet: ch14b/tag-kinds/02-annotated -->
```text
$ git tag -a v1.0.0 -m "inference-gateway 1.0.0" -m "First release with rate limits."
$ git count-objects | cut -d, -f1
12 objects
$ cat .git/refs/tags/v1.0.0
b69624883fa40e51cbbf4c4baf49365ba1caa02e
$ git cat-file -t v1.0.0
tag
$ git cat-file -p v1.0.0
object eb112a5c44b0b2092c4ef2cae6e75b16da000f73
type commit
tag v1.0.0
tagger Lab User <you@example.com> 1788756060 +0530

inference-gateway 1.0.0

First release with rate limits.
```
<!-- /snippet -->

Twelve objects where there were eleven. The ref holds `b696248`, the ID of the tag object; the tag object's `object` line holds the commit `eb112a5`. Getting from one to the other is called peeling:

<!-- snippet: ch14b/tag-kinds/03-peel -->
```text
$ git rev-parse v1.0.0 'v1.0.0^{tag}' 'v1.0.0^{commit}' 'v1.0.0^{}' 'v1.0.0^{tree}'
b69624883fa40e51cbbf4c4baf49365ba1caa02e
b69624883fa40e51cbbf4c4baf49365ba1caa02e
eb112a5c44b0b2092c4ef2cae6e75b16da000f73
eb112a5c44b0b2092c4ef2cae6e75b16da000f73
406c0291b052f665e4581982583c94937f169d80
$ git show-ref --tags --dereference
eb112a5c44b0b2092c4ef2cae6e75b16da000f73 refs/tags/staging-2026-09-07
b69624883fa40e51cbbf4c4baf49365ba1caa02e refs/tags/v1.0.0
eb112a5c44b0b2092c4ef2cae6e75b16da000f73 refs/tags/v1.0.0^{}
$ git for-each-ref refs/tags --format='%(refname:short) | %(objecttype) %(objectname:short) | peeled: %(*objecttype) %(*objectname:short)'
staging-2026-09-07 | commit eb112a5 | peeled:  
v1.0.0 | tag b696248 | peeled: commit eb112a5
```
<!-- /snippet -->

`v1.0.0^{commit}` follows tag objects until it reaches a commit; `^{}` until it reaches anything that is not a tag. In `git show-ref --dereference` and `git ls-remote`, the line ending in `^{}` is the peeled value of the line above. Commands that want a commit (`git log v1.0.0`, `git switch --detach v1.0.0`) peel for you.

**Inside `.git`.** `git tag -a` writes one object and one ref. No reflog is written for tags unless `core.logAllRefUpdates` is `always` (Chapter 7). HEAD, the index and the working tree are not involved.

**Picture.**

```text
  refs/tags/staging-2026-09-07 ----------------------------+
                                                           v
  refs/tags/v1.0.0 --> tag b696248                  commit eb112a5 <-- refs/heads/main <-- HEAD
                       object eb112a5 --------------^      |
                       type   commit                       v
                       tag    v1.0.0                   tree 406c029
                       tagger Lab User ... +0530
                       "inference-gateway 1.0.0"
```

**More than the latest commit.** A tag can name an older commit, `-m` alone implies `-a`, and the tagger date is the moment of tagging, not of the commit:

<!-- snippet: ch14b/tag-kinds/05-older-commit -->
```text
$ git tag -a v0.9.0 -m "Internal preview" HEAD~1
$ git tag -m "Rate limits verified on staging" v1.0.0-verified
$ git tag -n1
staging-2026-09-07 Add rate limits
v0.9.0          Internal preview
v1.0.0          inference-gateway 1.0.0
v1.0.0-verified Rate limits verified on staging
$ git for-each-ref refs/tags --format='%(refname:short) %(objecttype) %(creatordate:iso)'
staging-2026-09-07 commit 2026-09-07 10:05:00 +0530
v0.9.0 tag 2026-09-07 10:21:00 +0530
v1.0.0 tag 2026-09-07 10:11:00 +0530
v1.0.0-verified tag 2026-09-07 10:22:00 +0530
```
<!-- /snippet -->

A tag can also name a blob, a tree or another tag. Pro Git reports that the Git project's maintainer publishes a public key this way, as a tagged blob ([Maintaining a Project](https://git-scm.com/book/en/v2/Distributed-Git-Maintaining-a-Project)). A nested tag is almost always a mistake, and Git 2.55 says so:

<!-- snippet: ch14b/tag-kinds/06-not-a-commit -->
```text
# A tag can name any object. Here: one blob, the limits file as released, and then a tag of a tag.
$ git tag -a limits-schema-v1 -m "Limits file format, version 1" HEAD:config/limits.yaml
$ git cat-file -p limits-schema-v1 | head -3
object cb775a8efb9ad28e94389151972d6b06a5b263ee
type blob
tag limits-schema-v1
$ git tag -a v1.0.0-audited -m "Audit ticket SEC-88 closed" v1.0.0
hint: You have created a nested tag. The object referred to by your new tag is
hint: already a tag. If you meant to tag the object that it points to, use:
hint:
hint: 	git tag -f v1.0.0-audited v1.0.0^{}
hint: Disable this message with "git config set advice.nestedTag false"
$ git cat-file -p v1.0.0-audited | head -3
object b69624883fa40e51cbbf4c4baf49365ba1caa02e
type tag
tag v1.0.0-audited
$ git rev-parse v1.0.0-audited 'v1.0.0-audited^{tag}' 'v1.0.0-audited^{}'
6b410c8476aa6fcc8612bdcee3310b2654ae803d
6b410c8476aa6fcc8612bdcee3310b2654ae803d
eb112a5c44b0b2092c4ef2cae6e75b16da000f73
```
<!-- /snippet -->

Tag names obey the ref-name rules of [git-check-ref-format](https://git-scm.com/docs/git-check-ref-format): no spaces, no `~`, `^` or `:`. The `+` of a build-metadata suffix is allowed:

<!-- snippet: ch14b/tag-kinds/07-names -->
```text
$ git tag "v1.0 final"
fatal: 'v1.0 final' is not a valid tag name.
[exit status: 128]
$ git tag v1.0.0
fatal: tag 'v1.0.0' already exists
[exit status: 128]
$ git check-ref-format refs/tags/v1.0.0+build.7
[exit status: 0]
$ git check-ref-format "refs/tags/v1.0.0~1"
[exit status: 1]
```
<!-- /snippet -->

**Which kind when.** The manual's rule: annotated tags for releases, lightweight tags for private or temporary labels; `git describe` ignores lightweight tags by default for that reason. An annotated tag also answers "who released this, and when", which the last commit's author line cannot.

**In production.** An ML team tags the commit that produced each published model with an annotated tag `model/reranker/2026-09-07` and writes the evaluation run ID into the message. Two years later `git show` on that tag still says which code, who released it and which evaluation justified it.

## 14B.9 Listing and sorting tags

`git tag` lists in byte order, which is wrong for version numbers:

<!-- snippet: ch14b/tag-listing/01-default-order -->
```text
$ git log --oneline --decorate
a247d58 (HEAD -> main) Document streaming
c4f3ec7 (tag: v2.0.0-rc.2, tag: v2.0.0, tag: nightly) Fix stream flush
004673b (tag: v2.0.0-rc.1) Add streaming responses
e9fdbea (tag: v1.10.0) Add token check
ad88f54 (tag: v1.9.0) Add health endpoint
eb112a5 (tag: v1.2.0) Add rate limits
516c4c3 Add model router
37da450 Add README
$ git tag
nightly
v1.10.0
v1.2.0
v1.9.0
v2.0.0
v2.0.0-rc.1
v2.0.0-rc.2
```
<!-- /snippet -->

<!-- snippet: ch14b/tag-listing/02-version-sort -->
```text
$ git tag --sort=version:refname
nightly
v1.2.0
v1.9.0
v1.10.0
v2.0.0
v2.0.0-rc.1
v2.0.0-rc.2
$ git -c versionsort.suffix=-rc tag --sort=version:refname
nightly
v1.2.0
v1.9.0
v1.10.0
v2.0.0-rc.1
v2.0.0-rc.2
v2.0.0
```
<!-- /snippet -->

`--sort=version:refname` compares the numeric parts as numbers, so `v1.10.0` follows `v1.9.0`. It still lists a pre-release *after* its release, because `-rc.1` is a longer string. `versionsort.suffix` names the suffixes that sort *before* the bare version. Both can be made the default:

<!-- snippet: ch14b/tag-listing/03-configured -->
```text
$ git config set tag.sort version:refname
$ git config set versionsort.suffix -rc
$ git tag --list 'v2.*'
v2.0.0-rc.1
v2.0.0-rc.2
v2.0.0
$ git tag --list 'v[0-9]*' --sort=-version:refname | head -1
v2.0.0
```
<!-- /snippet -->

The last command is the usual scripted answer to "what is the newest release". Filters select by history, not by name:

<!-- snippet: ch14b/tag-listing/04-filters -->
```text
$ git tag --contains HEAD~2
nightly
v2.0.0-rc.1
v2.0.0-rc.2
v2.0.0
$ git tag --no-contains HEAD~2
v1.2.0
v1.9.0
v1.10.0
$ git tag --points-at HEAD~1
nightly
v2.0.0-rc.2
v2.0.0
$ git tag --merged v1.9.0
v1.2.0
v1.9.0
```
<!-- /snippet -->

`--contains <commit>` answers "which releases include this fix"; `--merged <commit>` answers "which releases are in the history of this commit". `--format` takes the fields of [git-for-each-ref](https://git-scm.com/docs/git-for-each-ref).

## 14B.10 Tags and remotes

Chapter 12 covers the transfer mechanics; this is the part specific to the tag namespace.

**Push sends tags only when asked.**

<!-- snippet: ch14b/tag-push/01-not-pushed -->
```text
$ git tag -a v1.0.0 -m "inference-gateway 1.0.0"
$ printf 'burst: 20\n' >> config/limits.yaml
$ git commit -q -am "Allow short bursts"
$ git push
To ../../server/inference-gateway.git
   d20ef7a..fa279e8  main -> main
$ git ls-remote --tags origin
```
<!-- /snippet -->

<!-- snippet: ch14b/tag-push/02-push-one -->
```text
$ git push origin v1.0.0
To ../../server/inference-gateway.git
 * [new tag]         v1.0.0 -> v1.0.0
$ git ls-remote --tags origin
3caaa3907d5f3c3071cdfebad5c416881fa9be07	refs/tags/v1.0.0
d20ef7a61e04035281b8b38ed0d78ee612252220	refs/tags/v1.0.0^{}
```
<!-- /snippet -->

`git push origin v1.0.0` 🟡 CAUTION publishes one tag. `git push --follow-tags` sends, with the branch, every *annotated* tag that points into the commits being pushed and is missing on the server; `push.followTags=true` makes that the default. `git push --tags` sends every tag you have, including the private ones:

<!-- snippet: ch14b/tag-push/03-follow-tags -->
```text
$ git tag -a v1.0.1 -m "inference-gateway 1.0.1"
$ git tag canary-ok
$ printf 'retry_after_seconds: 2\n' >> config/limits.yaml
$ git commit -q -am "Tell clients when to retry"
$ git tag wip-retry-header
$ git push --follow-tags
To ../../server/inference-gateway.git
   fa279e8..46cb046  main -> main
 * [new tag]         v1.0.1 -> v1.0.1
$ git ls-remote --tags origin
3caaa3907d5f3c3071cdfebad5c416881fa9be07	refs/tags/v1.0.0
d20ef7a61e04035281b8b38ed0d78ee612252220	refs/tags/v1.0.0^{}
65ad079e6bee92a0439fecf06a757ee24052b697	refs/tags/v1.0.1
fa279e82e36171f73f18c59df2c68bef182e5601	refs/tags/v1.0.1^{}
```
<!-- /snippet -->

`v1.0.1` went. The lightweight tags `canary-ok` and `wip-retry-header` stayed, which is the point of `--follow-tags`.

**Fetch follows tags.** A fetch brings every tag that points into the history it downloads, of either kind, and never updates a tag you already have (Chapter 12, section 12.4):

<!-- snippet: ch14b/tag-push/04-colleague-fetches -->
```text
$ cd ../../asha/inference-gateway
$ git fetch
From ../../server/inference-gateway
   d20ef7a..46cb046  main       -> origin/main
 * [new tag]         v1.0.0     -> v1.0.0
 * [new tag]         v1.0.1     -> v1.0.1
$ git tag
v1.0.0
v1.0.1
```
<!-- /snippet -->

**Deleting.** There are three places a tag lives, and each needs its own command:

<!-- snippet: ch14b/tag-push/05-delete -->
```text
$ cd ../../you/inference-gateway
$ git tag -d canary-ok
Deleted tag 'canary-ok' (was fa279e8)
$ git push origin --delete v1.0.1
To ../../server/inference-gateway.git
 - [deleted]         v1.0.1
$ git ls-remote --tags origin
3caaa3907d5f3c3071cdfebad5c416881fa9be07	refs/tags/v1.0.0
d20ef7a61e04035281b8b38ed0d78ee612252220	refs/tags/v1.0.0^{}
$ git tag
v1.0.0
v1.0.1
wip-retry-header
```
<!-- /snippet -->

`git tag -d` 🟡 CAUTION removes your ref. `git push origin --delete <tag>` 🔴 DANGEROUS removes the server's (the same as pushing `:refs/tags/<tag>`); your local `v1.0.1` is still there, and so is everyone else's:

<!-- snippet: ch14b/tag-push/06-other-clones-keep-it -->
```text
$ cd ../../asha/inference-gateway
$ git tag bisect-good-2026-09-07 HEAD~1
$ git fetch --prune
$ git tag
bisect-good-2026-09-07
v1.0.0
v1.0.1
$ git fetch --prune --prune-tags
From ../../server/inference-gateway
 - [deleted]         (none)     -> bisect-good-2026-09-07
 - [deleted]         (none)     -> v1.0.1
$ git tag
v1.0.0
```
<!-- /snippet -->

`git fetch --prune` does not touch tags. `git fetch --prune --prune-tags` 🔴 DANGEROUS makes your tags equal to the server's: it deleted Asha's private `bisect-good-2026-09-07` along with `v1.0.1`. And a deleted tag that someone still holds comes back with their next `git push --tags`.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git tag <name>`, `-a`, `-s` | unchanged | unchanged | unchanged | unchanged | new `refs/tags/<name>`; with `-a` or `-s` also a tag object | unchanged | unchanged |
| `git tag -f <name>` | unchanged | unchanged | unchanged | unchanged | ref rewritten; the old tag object becomes unreachable; no reflog | unchanged | unchanged |
| `git tag -d <name>` | unchanged | unchanged | unchanged | unchanged | ref deleted | unchanged | unchanged |
| `git push origin <tag>` | unchanged | unchanged | unchanged | unchanged | unchanged | new `refs/tags/<tag>` and its objects | the tag appears; a ruleset may refuse it (Chapter 18) |
| `git push --force origin <tag>`, `--delete <tag>` | unchanged | unchanged | unchanged | unchanged | unchanged | tag ref replaced or deleted | a release built on the tag is affected (Chapter 15) |
| `git fetch --tags --force` | unchanged | unchanged | unchanged | unchanged | local tags overwritten by the server's | unchanged | unchanged |

## 14B.11 Why a published tag must not move

**In one sentence.** Every clone keeps its own copy of each tag and never updates it by itself, so moving a tag on the server does not move it anywhere else: it creates two things with one name.

**See it.** `v1.2.0` is released; you and Asha both have it. An hour later a bug is fixed on `main`, and someone decides that `v1.2.0` should include the fix:

<!-- snippet: ch14b/moved-tag/02-move -->
```text
# A bug is found an hour after the release. The fix lands on main, and the tag is "corrected".
$ printf 'requests_per_minute: 60\nmax_tokens: 4096\n' > config/limits.yaml
$ git commit -q -am "Fix max_tokens limit"
$ git push -q
$ git tag -f -a v1.2.0 -m "inference-gateway 1.2.0"
Updated tag 'v1.2.0' (was 5b231b5)
$ git push origin v1.2.0
To ../../server/inference-gateway.git
 ! [rejected]        v1.2.0 -> v1.2.0 (already exists)
error: failed to push some refs to '../../server/inference-gateway.git'
hint: Updates were rejected because the tag already exists in the remote.
[exit status: 1]
$ git push --force origin v1.2.0
To ../../server/inference-gateway.git
 + 5b231b5...5a0dc77 v1.2.0 -> v1.2.0 (forced update)
```
<!-- /snippet -->

Git refused twice: `git tag` needed `-f` 🟡 CAUTION, and the push was rejected ("already exists") until `--force` 🔴 DANGEROUS. Asha pulls:

<!-- snippet: ch14b/moved-tag/03-asha -->
```text
$ cd ../../asha/inference-gateway
$ git pull
From ../../server/inference-gateway
   d20ef7a..2518733  main       -> origin/main
Updating d20ef7a..2518733
Fast-forward
 config/limits.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log --oneline --decorate
2518733 (HEAD -> main, origin/main, origin/HEAD) Fix max_tokens limit
d20ef7a (tag: v1.2.0) Add rate limits
73c05d1 Add model router
dfbc830 Add README
$ git show v1.2.0:config/limits.yaml
requests_per_minute: 60
max_tokens: 2048
```
<!-- /snippet -->

Her `main` has the fix. Her `v1.2.0` is where it always was. A machine that clones now gets the other one:

<!-- snippet: ch14b/moved-tag/04-fresh-clone -->
```text
$ cd ../..
$ git clone -q server/inference-gateway.git ci/inference-gateway
$ cd ci/inference-gateway
$ git log --oneline --decorate
2518733 (HEAD -> main, tag: v1.2.0, origin/main, origin/HEAD) Fix max_tokens limit
d20ef7a Add rate limits
73c05d1 Add model router
dfbc830 Add README
$ git show v1.2.0:config/limits.yaml
requests_per_minute: 60
max_tokens: 4096
```
<!-- /snippet -->

One clone's `v1.2.0` has `max_tokens: 2048`, the other's `4096`. Both builds are labelled 1.2.0.

**Picture.**

```text
  server                      Asha's clone                 CI clone (cloned after the move)
  v1.2.0 -> 2518733 (moved)   v1.2.0 -> d20ef7a (kept)     v1.2.0 -> 2518733

  d20ef7a  Add rate limits       <- what was released as 1.2.0
  2518733  Fix max_tokens limit  <- what the server now calls 1.2.0
```

**Detect it.** Compare the server's peeled tag with yours; `git fetch --tags` also reports the clash:

<!-- snippet: ch14b/moved-tag/05-detect -->
```text
$ cd ../../asha/inference-gateway
# What the server says the tag is, and what this clone says it is:
$ git ls-remote origin 'refs/tags/v1.2.0^{}'
2518733b711886bd82418641eb2434765079e288	refs/tags/v1.2.0^{}
$ git rev-parse 'v1.2.0^{commit}'
d20ef7a61e04035281b8b38ed0d78ee612252220
$ git fetch --tags
From ../../server/inference-gateway
 ! [rejected] v1.2.0     -> v1.2.0  (would clobber existing tag)
[exit status: 1]
```
<!-- /snippet -->

```text
Observed behavior : two builds labelled v1.2.0 contain different code.
Git state         : refs/tags/v1.2.0 names d20ef7a in clones that fetched before the move and
                    2518733 on the server and in clones made after it.
Mechanism         : fetch creates missing tags and refuses to overwrite existing ones ("would
                    clobber existing tag"); a plain fetch does not even report the difference.
Root cause        : a published tag was replaced with git tag -f and git push --force.
Why Git does this : a tag name is a promise about content. The manual: Git "does not (and it
                    should not) change tags behind users back".
Correct fix       : put the tag back where it was published; release the new content under a new name.
Prevention        : server-side rule that existing release tags cannot be updated or deleted;
                    deploy by commit ID or image digest, not by tag name alone.
```

**Repair it.** `v1.2.0` goes back, and the fix ships as `v1.2.1`. Asha's clone still has the original tag object, so she can restore it:

<!-- snippet: ch14b/moved-tag/06-repair -->
```text
# The sane repair: put v1.2.0 back where it was published, and release the fix as v1.2.1.
# Asha still has the original tag object, so she can restore it.
$ git push --force origin v1.2.0
To ../../server/inference-gateway.git
 + 5a0dc77...5b231b5 v1.2.0 -> v1.2.0 (forced update)
$ cd ../../you/inference-gateway
$ git fetch --tags --force
From ../../server/inference-gateway
 t [tag update]      v1.2.0     -> v1.2.0
$ git tag -a v1.2.1 -m "inference-gateway 1.2.1: fix max_tokens limit"
$ git push origin v1.2.1
To ../../server/inference-gateway.git
 * [new tag]         v1.2.1 -> v1.2.1
$ git log --oneline --decorate
2518733 (HEAD -> main, tag: v1.2.1, origin/main, origin/HEAD) Fix max_tokens limit
d20ef7a (tag: v1.2.0) Add rate limits
73c05d1 Add model router
dfbc830 Add README
```
<!-- /snippet -->

Clones that picked up the moved tag in between must be corrected by hand with 🟡 `git fetch --tags --force`. If nobody kept the original ref, the tag object is usually still in someone's object database as a "dangling tag" (Lab 13.2).

**Prevent it.** Two settings of plain Git sound as if they would help:

<!-- snippet: ch14b/moved-tag/08-server-settings -->
```text
# Two server settings that sound as if they protect tags. Set them and try.
$ cd ../../you/inference-gateway
$ git -C ../../server/inference-gateway.git config set receive.denyNonFastForwards true
$ git -C ../../server/inference-gateway.git config set receive.denyDeletes true
$ git tag -a v1.3.0-rc.1 -m "Release candidate"
$ git push -q origin v1.3.0-rc.1
$ git tag -f -a v1.3.0-rc.1 -m "Release candidate, moved" HEAD~1
Updated tag 'v1.3.0-rc.1' (was d15e77e)
$ git push --force origin v1.3.0-rc.1
To ../../server/inference-gateway.git
 + d15e77e...cc3836f v1.3.0-rc.1 -> v1.3.0-rc.1 (forced update)
[exit status: 0]
$ git push origin --delete v1.3.0-rc.1
To ../../server/inference-gateway.git
 - [deleted]         v1.3.0-rc.1
[exit status: 0]
```
<!-- /snippet -->

Both were accepted. In Git 2.55.0 the code behind `receive.denyNonFastForwards` and `receive.denyDeletes` applies them only to refs under `refs/heads/` ([receive-pack.c](https://github.com/git/git/blob/v2.55.0/builtin/receive-pack.c)); the manual's wording does not say so. On a plain Git server, tags are protected by a hook:

<!-- snippet: ch14b/moved-tag/09-update-hook -->
```text
# A server-side update hook: an existing tag under refs/tags/v* can be neither moved nor deleted.
$ cat ../../update-hook
#!/bin/sh
# update hook: called once per ref with <ref> <old-id> <new-id>.
# A release tag may be created. It may not be moved or deleted.
ref=$1 old=$2
case "$ref" in
refs/tags/v*)
  if ! printf '%s' "$old" | grep -q '^0*$'; then
    echo "policy: $ref is published and immutable; release a new version" >&2
    exit 1
  fi ;;
esac
exit 0
$ cp ../../update-hook ../../server/inference-gateway.git/hooks/update
$ chmod +x ../../server/inference-gateway.git/hooks/update
$ git push -q origin v1.3.0-rc.1
$ git tag -f -a v1.3.0-rc.1 -m "Release candidate, moved again" HEAD
Updated tag 'v1.3.0-rc.1' (was cc3836f)
$ git push --force origin v1.3.0-rc.1
remote: policy: refs/tags/v1.3.0-rc.1 is published and immutable; release a new version        
remote: error: hook declined to update refs/tags/v1.3.0-rc.1        
To ../../server/inference-gateway.git
 ! [remote rejected] v1.3.0-rc.1 -> v1.3.0-rc.1 (hook declined)
error: failed to push some refs to '../../server/inference-gateway.git'
[exit status: 1]
$ git push origin --delete v1.3.0-rc.1
remote: policy: refs/tags/v1.3.0-rc.1 is published and immutable; release a new version        
remote: error: hook declined to update refs/tags/v1.3.0-rc.1        
To ../../server/inference-gateway.git
 ! [remote rejected] v1.3.0-rc.1 (hook declined)
error: failed to push some refs to '../../server/inference-gateway.git'
[exit status: 1]
```
<!-- /snippet -->

> **GitHub, not Git.** On GitHub the equivalent is a tag ruleset that restricts updates and deletions ([Chapter 18](ch18-branch-protection.md)); tag protection rules were retired in August 2024 in favor of rulesets ([sunset notice](https://github.blog/changelog/2024-05-29-sunset-notice-tag-protections/)). A *release* is a GitHub object layered on a Git tag, and an immutable release additionally locks the tag and its assets ([Chapter 15](ch15-github.md)).

**In production.** The CTO's third question is also a supply-chain question. The Phase 0 report records that third-party GitHub Actions referenced by tag were repointed in real attacks, which is why this course pins actions by full commit ID (Chapter 21A). A tag is a mutable name held by someone else: record the commit ID next to every tag you depend on.

## 14B.12 `git describe`: a version from history

**In one sentence.** `git describe` names a commit by the nearest annotated tag in its history, the number of commits since that tag, and the commit's abbreviated ID.

**Precisely.** If a tag points at the commit, the output is the tag name. Otherwise Git walks back through history, finds tagged ancestors, picks the one with the fewest commits between it and the commit, and prints `<tag>-<count>-g<abbreviated-id>`; the `g` stands for "git" ([git-describe](https://git-scm.com/docs/git-describe)). Lightweight tags are ignored unless you pass `--tags`.

<!-- snippet: ch14b/describe/03-after-the-tag -->
```text
$ git log --oneline --decorate
c053f0d (HEAD -> main) Add token check
f37f723 Add health endpoint
eb112a5 (tag: v1.0.0, tag: staging-ok) Add rate limits
516c4c3 Add model router
37da450 Add README
$ git describe
v1.0.0-2-gc053f0d
$ git rev-parse --short HEAD
c053f0d
$ git rev-list --count v1.0.0..HEAD
2
$ git log --oneline "$(git describe)" -1
c053f0d Add token check
```
<!-- /snippet -->

`v1.0.0-2-gc053f0d`: two commits after `v1.0.0`, at commit `c053f0d`. The whole string is also a valid revision, so a version printed by a running service can be pasted into `git show`.

<!-- snippet: ch14b/describe/05-dirty -->
```text
$ printf 'def check(token):\n    return token == "letmein"\n' > gateway/auth.py
$ git describe --dirty
v1.0.0-2-gc053f0d-dirty
$ git describe --dirty=+local
v1.0.0-2-gc053f0d+local
$ git restore gateway/auth.py
$ git describe --dirty
v1.0.0-2-gc053f0d
```
<!-- /snippet -->

`--dirty` appends a mark when tracked files differ from HEAD, so a build from a modified working tree cannot pass as a release.

<!-- snippet: ch14b/describe/06-which-tags -->
```text
$ git tag -a v1.1.0-rc.1 -m "Release candidate" HEAD~1
$ git tag deployed-staging
$ git describe
v1.1.0-rc.1-1-gc053f0d
$ git describe --exclude '*-rc.*'
v1.0.0-2-gc053f0d
$ git describe --tags
deployed-staging
$ git describe --tags --match 'v[0-9]*'
v1.1.0-rc.1-1-gc053f0d
```
<!-- /snippet -->

`--match` and `--exclude` take globs and decide which tags may be used. Other options: `--abbrev=0` prints only the nearest tag; `--long` always prints the full form; `--exact-match` fails unless the commit itself is tagged; `--first-parent` ignores tags that arrived through merged branches; `--contains` asks which tag comes *after* this commit.

**Three ways it fails.**

<!-- snippet: ch14b/describe/01-no-tags -->
```text
$ git describe
fatal: No names found, cannot describe anything.
[exit status: 128]
$ git describe --always
eb112a5
$ git tag staging-ok
$ git describe
fatal: No annotated tags can describe 'eb112a5c44b0b2092c4ef2cae6e75b16da000f73'.
However, there were unannotated tags: try --tags.
[exit status: 128]
$ git describe --tags
staging-ok
```
<!-- /snippet -->

No tags at all; only lightweight tags; and the third, which is the common one in CI:

<!-- snippet: ch14b/describe-shallow/02-shallow -->
```text
$ cd ../..
$ git clone -q --depth 1 "file://$PWD/server/inference-gateway.git" ci/inference-gateway
$ cd ci/inference-gateway
$ git rev-parse --is-shallow-repository
true
$ git log --oneline
72212ba Add token check
$ git tag
$ git describe
fatal: No names found, cannot describe anything.
[exit status: 128]
$ git describe --always
72212ba
```
<!-- /snippet -->

A depth-1 clone has one commit and no tags. Fetching the tag is not enough, because the commits *between* the tag and the tip are still missing and Git cannot count them:

<!-- snippet: ch14b/describe-shallow/03-tags-without-history -->
```text
$ git fetch -q --depth 1 origin tag v1.0.0
$ git tag
v1.0.0
$ git describe
fatal: No tags can describe '72212bae7bd9bd85bd7300a9a92d9f8d50f89807'.
Try --always, or create some tags.
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ch14b/describe-shallow/04-unshallow -->
```text
$ git fetch --unshallow
$ git rev-parse --is-shallow-repository
false
$ git describe
v1.0.0-2-g72212ba
```
<!-- /snippet -->

```text
Observed behavior : the build in CI gets a fallback version or fails; locally the version is v1.0.0-2-g72212ba.
Git state         : the CI checkout is shallow (one commit) and has no refs/tags/.
Mechanism         : git describe needs a tagged ancestor and the commits between it and HEAD.
Root cause        : the checkout step fetched one commit; tools that derive versions from tags
                    (git describe, setuptools-scm and similar) fall back or fail.
Why Git does this : a shallow clone is a deliberate trade of history for speed.
Correct fix       : fetch full history and tags in jobs that compute a version.
Prevention        : make the release job fail when git describe --exact-match fails.
```

> **GitHub, not Git.** `actions/checkout` fetches one commit and no tags by default; `fetch-depth: 0` fetches everything ([checkout README](https://github.com/actions/checkout/blob/v7.0.1/README.md)). [Chapter 20A](ch20a-actions-fundamentals.md) returns to this.

## 14B.13 Semantic Versioning 2.0.0

Git attaches no meaning to a tag name. [Semantic Versioning 2.0.0](https://semver.org/) is the convention most projects put on top:

- A version is `MAJOR.MINOR.PATCH`. Incompatible API changes raise MAJOR; backward-compatible additions raise MINOR; backward-compatible fixes raise PATCH.
- A released version is immutable: its contents "MUST NOT be modified". Any change is a new version. This is the same rule as section 14B.11, stated for packages.
- `0.y.z` is initial development, where anything may change.
- A pre-release is marked by a hyphen and dot-separated identifiers (`1.3.0-rc.1`) and has *lower* precedence than the release (`1.3.0-rc.1 < 1.3.0`). Numeric identifiers compare as numbers, so `rc.2 < rc.11`.
- Build metadata follows a plus sign (`1.3.0+build.7`) and is ignored when versions are compared.
- The specification's FAQ says that `v1.2.3` is not itself a semantic version; the `v` prefix is a common way to mark a tag as a version. The version is `1.2.3`.

Three consequences for Git. The pre-release rule is why section 14B.9 needed `versionsort.suffix`. The output of `git describe` (`v1.0.0-2-gc053f0d`) is not a valid semantic version of a later build, because by the pre-release rule it would sort *before* `1.0.0`; tools that publish packages translate it into their ecosystem's format. And SemVer describes a public API: for a service that nobody links against, a date-based scheme carries the same information with less ceremony.

## 14B.14 Release branches, on the Git side

When more than one version is in use, a tag is not enough: the old version needs fixes that must not bring new features with them. A release branch is an ordinary branch that starts at the release tag.

<!-- snippet: ch14b/release-branch/02-backport -->
```text
$ git cherry-pick -x main~1
[release/1.2 c40960e] Fix max_tokens limit
 Date: Mon Sep 7 10:08:00 2026 +0530
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log -1 --format=%B
Fix max_tokens limit

(cherry picked from commit 362b3592d29ea9c07389c0782fd46c24269b6a3f)

$ git tag -a v1.2.1 -m "inference-gateway 1.2.1: fix max_tokens limit"
```
<!-- /snippet -->

The fix was made on `main` first and copied to `release/1.2` with `git cherry-pick -x`, which records the source commit in the message (Chapter 10). Then the patch release is tagged on the release branch:

<!-- snippet: ch14b/release-branch/03-two-lines -->
```text
$ git log --graph --oneline --decorate --all
* c40960e (HEAD -> release/1.2, tag: v1.2.1) Fix max_tokens limit
| * 8ed5c59 (main) Add batch endpoint
| * 362b359 Fix max_tokens limit
| * 27d1fb6 Add streaming responses
|/  
* eb112a5 (tag: v1.2.0) Add rate limits
* 516c4c3 Add model router
* 37da450 Add README
$ git describe release/1.2
v1.2.1
$ git describe main
v1.2.0-3-g8ed5c59
```
<!-- /snippet -->

`main` describes itself as `v1.2.0-3-g8ed5c59` although 1.2.1 has been released: `v1.2.1` is not an ancestor of `main`, and `git describe` only looks backward along history. Questions about content need the tools that understand copies:

<!-- snippet: ch14b/release-branch/04-what-contains-the-fix -->
```text
$ git tag --contains main~1
$ git tag --contains release/1.2
v1.2.1
$ git tag --merged main
v1.2.0
$ git cherry -v release/1.2 main
+ 27d1fb6a67cdb41e87d5771c3e10310823ee0dcb Add streaming responses
- 362b3592d29ea9c07389c0782fd46c24269b6a3f Fix max_tokens limit
+ 8ed5c59df2f47f80f396b5ba11769efbe1d6491e Add batch endpoint
```
<!-- /snippet -->

No tag *contains* the original fix commit `362b359`, because the release has the copy `c40960e`. `git cherry` compares patches, not IDs, and its `-` line says that the fix on `main` has an equivalent on the release branch. When 1.3.0 is cut from `main`, the same comparison separates what is new from what was backported:

<!-- snippet: ch14b/release-branch/05-next-minor -->
```text
$ git switch -q main
$ git tag -a v1.3.0 -m "inference-gateway 1.3.0"
$ git tag --sort=version:refname
v1.2.0
v1.2.1
v1.3.0
$ git describe main
v1.3.0
$ git log --oneline v1.2.1..v1.3.0
8ed5c59 Add batch endpoint
362b359 Fix max_tokens limit
27d1fb6 Add streaming responses
$ git log --oneline --cherry-pick --right-only v1.2.1...v1.3.0
8ed5c59 Add batch endpoint
27d1fb6 Add streaming responses
```
<!-- /snippet -->

Two conventions exist for the direction of a fix (Phase 0 report): the Git project fixes on the oldest maintained branch and merges upward ([gitworkflows](https://git-scm.com/docs/gitworkflows)); trunk-based practice fixes on the main line and cherry-picks to the release branch, as here. [Chapter 27](ch27-open-source-team-workflows.md) discusses the choice.

**In production.** A model-serving team runs `1.2.x` for a regulated customer and `1.3.x` for everyone else. "Is the token-limit fix in what the regulated customer runs?" is answered by `git cherry -v release/1.2 main` and by the trailer that `-x` wrote, not by looking for the commit ID on the release branch, where it will never be.

## 14B.15 Signatures: what is signed, and by which program

**In one sentence.** A Git signature is a detached cryptographic signature over the bytes of one commit or one annotated tag, produced by an external program and stored inside that object.

**Analogy.** A seal pressed onto one page of the ledger. Because each page cites earlier pages by numbers computed from their content, the seal vouches for the whole history behind it. The analogy breaks where it matters most: the seal says which *ring* was used, not whose hand held it.

**Precisely.** Git computes the object without a signature, hands those bytes to a signing program, and embeds the result: in a commit as the `gpgsig` header introduced in Chapter 6 (section 6.11), in a tag as a block appended to the message ([gitformat-signature](https://git-scm.com/docs/gitformat-signature)). Since the signature is part of the object, it is covered by the object ID; signing an existing commit means writing a new commit. `gpg.format` chooses the program:

| `gpg.format` | Program (overridable with `gpg.<format>.program`) | Key chosen by | Who decides that the key is trusted |
|---|---|---|---|
| `openpgp` (default) | `gpg` | `user.signingKey`, else the committer identity | your GnuPG keyring and its trust levels (`gpg.minTrustLevel`) |
| `x509` (Git 2.19) | `gpgsm` | `user.signingKey`, else the committer identity | the certificate chain |
| `ssh` (Git 2.34) | `ssh-keygen` | `user.signingKey` (a key file, or a literal `key::...` with an agent), else `gpg.ssh.defaultKeyCommand` | the file named by `gpg.ssh.allowedSignersFile` |

Git itself does no cryptography. To show what it asks of the program without starting `gpg`, `gpgsm` or an agent, this demo puts a stand-in in their place that prints its arguments and fails:

<!-- snippet: ch14b/signing-backends/02-openpgp -->
```text
$ git -c gpg.program=~/lab-bin/show-args commit -S --allow-empty -m "Signed with OpenPGP"
error: gpg failed to sign the data:
signing program called with: --status-fd=2 -bsau Lab User <you@example.com>

fatal: failed to write commit object
[exit status: 128]
```
<!-- /snippet -->

"`gpg failed to sign the data`" is the generic message for "the signing program returned an error": no key for that identity, an agent that cannot ask for the passphrase, a wrong `gpg.program`. The key was selected by the committer identity because `user.signingKey` is not set.

<!-- snippet: ch14b/signing-backends/04-ssh -->
```text
$ git -c gpg.format=ssh -c gpg.ssh.program=~/lab-bin/show-args commit -S --allow-empty -m "Signed with SSH"
fatal: either user.signingkey or gpg.ssh.defaultKeyCommand needs to be configured
[exit status: 128]
$ git -c gpg.format=ssh -c gpg.ssh.program=~/lab-bin/show-args -c user.signingKey=~/keys/signing_key.pub commit -S --allow-empty -m "Signed with SSH"
error: signing program called with: -Y sign -n git -f $LAB/ch14b/signing-backends/home/keys/signing_key.pub <file with the payload>

fatal: failed to write commit object
[exit status: 128]
```
<!-- /snippet -->

The SSH backend has no default key. With one, it runs `ssh-keygen -Y sign` with the namespace `git`. The rest of this chapter uses SSH signing: you already have SSH keys, and the trust file is plain text. OpenPGP and X.509 signing are not run here, because both would start an agent process.

## 14B.16 SSH signing, end to end

This demo creates a key pair inside the sandbox, without passphrase or agent. It is volatile: your key, signatures and IDs will differ. A real signing key has a passphrase and lives in an agent or a hardware token ([Chapter 16](ch16-authentication.md)).

<!-- snippet: ch14b/ssh-signing/01-key -->
```text
$ mkdir ~/keys
$ ssh-keygen -q -t ed25519 -N '' -C 'you@example.com signing key 2026' -f ~/keys/signing_key
$ ls ~/keys
signing_key
signing_key.pub
$ cat ~/keys/signing_key.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPeZ8qdHWOUuKtL/yAKkDk4n+e6oo2sO2JTJ8lmdYFDE you@example.com signing key 2026
$ ssh-keygen -l -f ~/keys/signing_key.pub
256 SHA256:wIC1YB2G8ErM9XCgJQ+pItmnhwF/fv4lGfAmWeriHGs you@example.com signing key 2026 (ED25519)
```
<!-- /snippet -->

<!-- snippet: ch14b/ssh-signing/02-configure -->
```text
$ git config set --global gpg.format ssh
$ git config set --global user.signingKey ~/keys/signing_key.pub
$ git config get --all --show-names --regexp "^(gpg|user\.signingkey)"
user.signingkey $LAB/ch14b/ssh-signing/home/keys/signing_key.pub
gpg.format ssh
```
<!-- /snippet -->

`user.signingKey` names the *public* key file. `ssh-keygen` finds the private key beside it, or in an agent. A signed commit, read as an object:

<!-- snippet: ch14b/ssh-signing/03-sign-a-commit -->
```text
$ printf 'burst: 20\n' >> config/limits.yaml
$ git commit -q -S -am "Allow short bursts"
$ git cat-file -p HEAD
tree c84890b7f7cbb711c04b9a7fb78410beb5897d9b
parent eb112a5c44b0b2092c4ef2cae6e75b16da000f73
author Lab User <you@example.com> 1788756300 +0530
committer Lab User <you@example.com> 1788756300 +0530
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAg95nyp0dY5S4q0v/IAqQOTif57q
 ijaw7YlMnyWZ1gUMQAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQJMccrn4Dmj2cHUPAHhz39NlMtXXlS2u+/lOewunSjVhvREL3WkYdp/G0PrihonpvT
 +ZHT0fNnmCm7pVB7KlHQ4=
 -----END SSH SIGNATURE-----

Allow short bursts
```
<!-- /snippet -->

`-S` 🟢 SAFE signs this one commit. The `gpgsig` header carries the signature; continuation lines start with a space. Now verify it:

<!-- snippet: ch14b/ssh-signing/04-verify-without-trust -->
```text
$ git verify-commit HEAD
error: gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification
[exit status: 1]
$ git log -1 --show-signature --format="%h %s"
error: gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification
No signature
f215ce4 Allow short bursts
$ git log -1 --format='%h  %G?  %s'
error: gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification
f215ce4  N  Allow short bursts
```
<!-- /snippet -->

```text
Observed behavior : git log --show-signature prints "No signature", and %G? prints N, for a
                    commit that visibly has a gpgsig header.
Git state         : the commit is signed. gpg.ssh.allowedSignersFile is not set.
Mechanism         : SSH verification means "find this key in my list of allowed signers".
                    Without a list Git does not start ssh-keygen at all and reports no result.
Root cause        : signing needs one key; verifying needs a statement of whom you trust.
Why Git does this : an SSH key has no owner written into it and no web of trust. The manual:
                    trust is "fully" when the key is in the file and "undefined" otherwise.
Correct fix       : create the allowed-signers file and point gpg.ssh.allowedSignersFile at it.
Prevention        : distribute the file with the signing setup; a team can keep it in the repository.
```

An allowed-signers line is a principal (an email address by convention), optional options, and a public key ([ssh-keygen](https://man.openbsd.org/ssh-keygen), "ALLOWED SIGNERS"). `namespaces="git"` restricts the key to Git signatures:

<!-- snippet: ch14b/ssh-signing/05-allowed-signers -->
```text
$ printf 'you@example.com namespaces="git" %s\n' "$(cut -d' ' -f1,2 ~/keys/signing_key.pub)" > ~/allowed_signers
$ cat ~/allowed_signers
you@example.com namespaces="git" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPeZ8qdHWOUuKtL/yAKkDk4n+e6oo2sO2JTJ8lmdYFDE
$ git config set --global gpg.ssh.allowedSignersFile ~/allowed_signers
$ git verify-commit HEAD
Good "git" signature for you@example.com with ED25519 key SHA256:wIC1YB2G8ErM9XCgJQ+pItmnhwF/fv4lGfAmWeriHGs
[exit status: 0]
$ git log -2 --show-signature --format="%h %an: %s"
Good "git" signature for you@example.com with ED25519 key SHA256:wIC1YB2G8ErM9XCgJQ+pItmnhwF/fv4lGfAmWeriHGs
f215ce4 Lab User: Allow short bursts
eb112a5 Lab User: Add rate limits
```
<!-- /snippet -->

The same object now verifies. Nothing in the repository changed; your statement of trust did. For scripts, the format placeholders:

<!-- snippet: ch14b/ssh-signing/06-placeholders -->
```text
$ git log -2 --format='%h  %G?  signer=%GS  trust=%GT  %s'
f215ce4  G  signer=you@example.com  trust=fully  Allow short bursts
eb112a5  N  signer=  trust=undefined  Add rate limits
$ git log -1 --format='%GK'
SHA256:wIC1YB2G8ErM9XCgJQ+pItmnhwF/fv4lGfAmWeriHGs
```
<!-- /snippet -->

| `%G?` | Meaning in the manual ([git-log](https://git-scm.com/docs/git-log)) | Seen with SSH in this chapter |
|---|---|---|
| `G` | good signature | key is in the allowed-signers file and valid at the signature's time |
| `B` | bad signature | object altered after signing; key listed in the revocation file |
| `U` | good signature, unknown validity | key not in the file, or outside its validity window |
| `N` | no signature | unsigned; also printed, with an error, when no allowed-signers file is configured |
| `X`, `Y`, `R`, `E` | expired signature, expired key, revoked key, cannot be checked | not produced by the SSH demos here |

**Signing by default, and tags.**

<!-- snippet: ch14b/ssh-signing/07-sign-by-default -->
```text
$ git config set --global commit.gpgSign true
$ git config set --global tag.gpgSign true
$ printf 'retry_after_seconds: 2\n' >> config/limits.yaml
$ git commit -q -am "Tell clients when to retry"
$ git commit -q --no-gpg-sign --allow-empty -m "Trigger the nightly evaluation"
$ git log -4 --format='%h  %G?  %GS  %s'
e32a07f  N    Trigger the nightly evaluation
9d47104  G  you@example.com  Tell clients when to retry
f215ce4  G  you@example.com  Allow short bursts
eb112a5  N    Add rate limits
```
<!-- /snippet -->

`commit.gpgSign=true` signs every commit; `--no-gpg-sign` opts one out. `tag.gpgSign=true` turns every annotated tag into a signed one, so `-m` is enough:

<!-- snippet: ch14b/ssh-signing/08-signed-tag -->
```text
$ git tag -m "inference-gateway 1.0.0" v1.0.0 HEAD~1
$ git cat-file -p v1.0.0
object 9d471046051e8d578b339ee37eb466c71e16b6ec
type commit
tag v1.0.0
tagger Lab User <you@example.com> 1788757380 +0530

inference-gateway 1.0.0
-----BEGIN SSH SIGNATURE-----
U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAg95nyp0dY5S4q0v/IAqQOTif57q
ijaw7YlMnyWZ1gUMQAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
AAAAQENhU0YSEgUB1RmZBsnzJdHgXZdddaBvXKoPIFK23QLUTUltL6Gr+o9kyWszNlomBF
apz4b7Ok5FFB+R/+c0swo=
-----END SSH SIGNATURE-----
$ git verify-tag v1.0.0
Good "git" signature for you@example.com with ED25519 key SHA256:wIC1YB2G8ErM9XCgJQ+pItmnhwF/fv4lGfAmWeriHGs
[exit status: 0]
$ git tag -v v1.0.0
Good "git" signature for you@example.com with ED25519 key SHA256:wIC1YB2G8ErM9XCgJQ+pItmnhwF/fv4lGfAmWeriHGs
object 9d471046051e8d578b339ee37eb466c71e16b6ec
type commit
tag v1.0.0
tagger Lab User <you@example.com> 1788757380 +0530

inference-gateway 1.0.0
```
<!-- /snippet -->

In a tag the signature follows the message. `git verify-tag`, `git tag -v` and `git verify-commit` exit non-zero on anything but a trusted good signature, so they work in scripts. What Git starts:

<!-- snippet: ch14b/ssh-signing/09-mechanism -->
```text
# Git does no cryptography itself. The programs it starts to sign and to verify:
$ GIT_TRACE=1 git commit -q --allow-empty -m 'Re-run the nightly evaluation' 2>&1 | grep -o 'run_command: ssh-keygen -Y [a-z-]* -n git'
run_command: ssh-keygen -Y sign -n git
$ GIT_TRACE=1 git verify-commit HEAD 2>&1 | grep -o 'run_command: ssh-keygen -Y [a-z-]*'
run_command: ssh-keygen -Y find-principals
run_command: ssh-keygen -Y verify
$ git verify-commit --raw HEAD
Good "git" signature for you@example.com with ED25519 key SHA256:wIC1YB2G8ErM9XCgJQ+pItmnhwF/fv4lGfAmWeriHGs
```
<!-- /snippet -->

One program to sign; two steps to verify: find which principal the key belongs to, then verify the signature for that principal.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git commit -S` | unchanged | as `git commit` | as `git commit` | moves to the new, signed commit | new commit object with a `gpgsig` header | unchanged | after a push: a verification badge, if the public key is registered as a signing key (Chapter 21B) |
| `git tag -s <name>` | unchanged | unchanged | unchanged | unchanged | new tag object with an appended signature; new ref | unchanged | unchanged until pushed |
| `git verify-commit`, `git verify-tag`, `git log --show-signature` | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged |

## 14B.17 What a signature covers, and what verification proves

**Everything in the object is covered.** Copy a signed commit, change one word of its message, keep the signature:

<!-- snippet: ch14b/signature-scope/01-tamper -->
```text
$ git log -1 --format='%h  %G?  %GS  %s'
b389204  G  you@example.com  Allow short bursts
# Write a second commit object: same headers, same signature, one word of the message changed.
$ git cat-file commit HEAD | sed 's/short bursts/unlimited bursts/' | git hash-object -t commit -w --stdin > ../forged-id
$ git cat-file -p "$(cat ../forged-id)" | tail -1
Allow unlimited bursts
$ git verify-commit "$(cat ../forged-id)"
Could not verify signature.
Signature verification failed: incorrect signature
[exit status: 1]
$ git log -1 --format='%G?  %s' "$(cat ../forged-id)"
B  Allow unlimited bursts
```
<!-- /snippet -->

The forged object has another ID, and its signature is `B`, bad. Tree, parents, author, committer, dates and message are all signed bytes; through the tree and parent IDs, a signature vouches for every file and every ancestor.

**Nothing outside the object is covered.**

<!-- snippet: ch14b/signature-scope/02-refs-are-not-signed -->
```text
# The signature is inside the object. Which refs point at the object is not part of it.
$ git branch hotfix/anything HEAD
$ git log -1 --format='%G?  %D' hotfix/anything
G  HEAD -> main, tag: v1.0.0, hotfix/anything
$ git update-ref refs/tags/v9.9.9 "$(git rev-parse v1.0.0)"
$ git verify-tag v9.9.9
Good "git" signature for you@example.com with ED25519 key SHA256:IBY0fLOBtdFj0fbHvPhR5Di74E0PfNUAA+UYVYfgHgw
[exit status: 0]
$ git cat-file -p v9.9.9 | sed -n 1,3p
object b3892048e77c43a09f64eedfeccc408eeb532e3a
type commit
tag v1.0.0
$ git tag -d v9.9.9
Deleted tag 'v9.9.9' (was 849e258)
```
<!-- /snippet -->

A signed commit stays validly signed on any branch, in any repository. Anyone who can push can serve your signed tag object under the name `v9.9.9`; the object still says `tag v1.0.0` inside, which is why a careful verifier compares that name with the one it asked for.

**Rewrites drop signatures.**

<!-- snippet: ch14b/signature-scope/03-rewrites-drop-signatures -->
```text
$ git commit -q --allow-empty -m "Trigger the nightly evaluation"
$ git log -2 --format='%h  %G?  %s'
65bce98  G  Trigger the nightly evaluation
b389204  G  Allow short bursts
$ git commit -q --amend --allow-empty --no-gpg-sign -m "Trigger the nightly evaluation run"
$ git log -2 --format='%h  %G?  %s'
2bc6aa4  N  Trigger the nightly evaluation run
b389204  G  Allow short bursts
$ git rebase -q --no-gpg-sign --force-rebase HEAD~2
$ git log -2 --format='%h  %G?  %s'
93c3833  N  Trigger the nightly evaluation run
14656b3  N  Allow short bursts
$ git rebase -q --gpg-sign --force-rebase HEAD~2
$ git log -2 --format='%h  %G?  %s'
7129bbb  G  Trigger the nightly evaluation run
acc22ee  G  Allow short bursts
```
<!-- /snippet -->

Amend, rebase and cherry-pick write new commits (Chapters 6, 9 and 10), signed only if the person running the command signs, and then with *their* key.

> **GitHub, not Git.** The same logic runs on the platform. According to GitHub's documentation, merge and squash commits made in the web interface are signed by GitHub, and commits produced by "rebase and merge" are not signed at all ([about commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)); Chapter 17 covers the merge methods.

**A key you do not list proves nothing to you.**

<!-- snippet: ch14b/signature-scope/04-unknown-key -->
```text
$ git -c user.signingKey=~/keys/stranger.pub commit -q --allow-empty -m "Bump the model default"
$ git verify-commit HEAD
Good "git" signature with ED25519 key SHA256:dvbzrGKgxrd5uBx6kt8ux+C+H3qGogE5fD3p/a8CHZA
No principal matched.
[exit status: 1]
$ git log -1 --format='%h  %G?  signer=%GS  trust=%GT  %s'
81b4414  U  signer=  trust=undefined  Bump the model default
```
<!-- /snippet -->

The mathematics is fine ("Good signature") and the answer is still a failure (`U`, exit status 1): nobody you trust is attached to that key.

**Key lifetimes rest on a date the signer chooses.** An allowed-signers entry can carry `valid-after` and `valid-before`; Git passes the *committer date* of the object as the time to check against:

<!-- snippet: ch14b/signature-scope/05-key-lifetime -->
```text
# The lab clock says 7 September 2026. Give the key a validity window that ended on 31 August.
$ printf 'you@example.com namespaces="git",valid-before="20260831" %s\n' "$(cut -d' ' -f1,2 ~/keys/you_2026.pub)" > ~/allowed_signers
$ git verify-commit HEAD~1
Good "git" signature with ED25519 key SHA256:IBY0fLOBtdFj0fbHvPhR5Di74E0PfNUAA+UYVYfgHgw
$LAB/ch14b/signature-scope/home/allowed_signers:1: key has expired: verify time 2026-09-07T10:30:00 > valid-before 2026-08-31T00:00:00

No principal matched.
[exit status: 1]
# The verify time is the committer date, and the committer date is whatever the committer says.
$ GIT_COMMITTER_DATE='2026-08-30T12:00:00+05:30' git commit -q --allow-empty -m 'Rotate the staging credentials'
$ git verify-commit HEAD
Good "git" signature for you@example.com with ED25519 key SHA256:IBY0fLOBtdFj0fbHvPhR5Di74E0PfNUAA+UYVYfgHgw
[exit status: 0]
$ git log -1 --format='%h  %G?  committed %cs  %s'
8c7d0a6  G  committed 2026-08-30  Rotate the staging credentials
```
<!-- /snippet -->

A commit dated after the key's end is rejected. A commit made today with `GIT_COMMITTER_DATE` set inside the window is accepted. Validity windows let you rotate keys without invalidating old signatures, which is what the manual offers them for. They do not protect against a stolen key: the thief chooses the date. For that there is the revocation file:

<!-- snippet: ch14b/signature-scope/06-revocation -->
```text
$ cut -d' ' -f1,2 ~/keys/you_2026.pub > ~/revoked_keys
$ git config set --global gpg.ssh.revocationFile ~/revoked_keys
$ git verify-commit HEAD
Could not verify signature.
[exit status: 1]
$ git log -1 --format='%h  %G?  %s'
8c7d0a6  B  Rotate the staging credentials
```
<!-- /snippet -->

A revoked key fails for every date, including all the honest signatures made before the theft.

**Picture.**

```text
   signed bytes (the commit without gpgsig)             not signed
   +--------------------------------------------+      +---------------------------------+
   | tree      -> every file, by hash           |      | refs: which branch or tag name  |
   | parent(s) -> all earlier history, by hash  |      | which repository, which fork    |
   | author    name <email> date                |      | who pushed it, and when         |
   | committer name <email> date                |      | reviews, CI results, approvals  |
   | message                                    |      | whether the author line is true |
   +--------------------------------------------+      +---------------------------------+
        |  ssh-keygen -Y sign -n git
        v
   gpgsig header (commit)  or  block after the message (tag)
```

| A verified signature proves | It does not prove |
|---|---|
| The object has not changed since it was signed | That the change is correct, reviewed or harmless |
| Someone with access to the private key signed it | Which person that was, if the key was shared, stolen or left unlocked |
| The key is one that *you* (or your platform) have decided to trust for that principal | That the author and committer lines name the signer (section 14B.18) |
| | When it was signed: the dates are the signer's claim |
| | That it belongs on this branch or in this release |

The Phase 0 report's example is the xz-utils backdoor of 2024: introduced by a contributor who had earned commit rights over two years, activated by a script that existed only in the release tarball ([timeline](https://research.swtch.com/xz-timeline)). Provenance is not safety.

## 14B.18 Author spoofing, locally

**In one sentence.** Author and committer are text supplied by whoever creates the commit, so anyone can create a commit that names you, and a server running plain Git will accept it.

**See it.** Asha has one genuine commit in the shared repository. You add two more "by Asha", first with an option and then with two configuration values:

<!-- snippet: ch14b/spoof-author/02-author-flag -->
```text
$ printf 'requests_per_minute: 6000\n' > config/limits.yaml
$ git commit -q -am "Raise the rate limit" --author="Asha Rao <asha@example.com>"
$ git log -1 --format='%h  author=%an <%ae>  committer=%cn <%ce>  %s'
fee79f6  author=Asha Rao <asha@example.com>  committer=Lab User <you@example.com>  Raise the rate limit
```
<!-- /snippet -->

<!-- snippet: ch14b/spoof-author/03-full-impersonation -->
```text
$ printf 'requests_per_minute: 60000\n' > config/limits.yaml
$ git -c user.name="Asha Rao" -c user.email=asha@example.com commit -q -am "Raise the rate limit again"
$ git log -3 --format='%h  author=%an <%ae>  committer=%cn <%ce>  %s'
6e10a38  author=Asha Rao <asha@example.com>  committer=Asha Rao <asha@example.com>  Raise the rate limit again
fee79f6  author=Asha Rao <asha@example.com>  committer=Lab User <you@example.com>  Raise the rate limit
39f0449  author=Asha Rao <asha@example.com>  committer=Asha Rao <asha@example.com>  Add health endpoint
```
<!-- /snippet -->

`--author` changed one field and left you as committer, which is how a patch from someone else is honestly recorded (Chapter 6). The second commit claims both fields. Compared with her real commit, there is no field that tells them apart:

<!-- snippet: ch14b/spoof-author/04-objects-compared -->
```text
# Her real commit and your forgery, header by header (tree, parent and dates differ, as for any two commits):
$ git cat-file -p HEAD~2 | sed -n "/^author/,/^committer/p"
author Asha Rao <asha@example.com> 1788756000 +0530
committer Asha Rao <asha@example.com> 1788756000 +0530
$ git cat-file -p HEAD | sed -n "/^author/,/^committer/p"
author Asha Rao <asha@example.com> 1788756480 +0530
committer Asha Rao <asha@example.com> 1788756480 +0530
```
<!-- /snippet -->

<!-- snippet: ch14b/spoof-author/05-server-accepts -->
```text
$ git push
To ../../server/inference-gateway.git
   39f0449..6e10a38  main -> main
$ git -C ../../server/inference-gateway.git log -3 --format='%h  %an <%ae>  %s'
6e10a38  Asha Rao <asha@example.com>  Raise the rate limit again
fee79f6  Asha Rao <asha@example.com>  Raise the rate limit
39f0449  Asha Rao <asha@example.com>  Add health endpoint
$ git shortlog -sne HEAD
     3	Asha Rao <asha@example.com>
     3	Lab User <you@example.com>
```
<!-- /snippet -->

The push was accepted, and `git shortlog` credits Asha with three commits. Git has no rule that the pusher must be the committer; who pushed is known only to the server's logs.

**With signatures.** The same forgery in a repository where both of you sign and both keys are in the allowed-signers file (a volatile demo):

<!-- snippet: ch14b/spoof-signed/03-signed-forgery -->
```text
# You cannot sign as Asha: you do not have her private key. You can sign with your own.
$ printf 'requests_per_minute: 60000\n' > config/limits.yaml
$ git -c user.name="Asha Rao" -c user.email=asha@example.com commit -q -S -am "Raise the rate limit again"
$ git verify-commit HEAD
Good "git" signature for you@example.com with ED25519 key SHA256:XpH8NGlAagHBiC1XlKWmz7zMcGZ2uC4HE68dHGQP3zg
[exit status: 0]
$ git log -3 --format='%h  %G?  author=%ae  signer=%GS  %s'
4687f7f  G  author=asha@example.com  signer=you@example.com  Raise the rate limit again
bc6a046  N  author=asha@example.com  signer=  Raise the rate limit
4306257  G  author=asha@example.com  signer=asha@example.com  Add health endpoint
```
<!-- /snippet -->

Three commits claim Asha as author. One is signed by her key. One is unsigned. One is signed, validly, by *your* key: `git verify-commit` exits 0, because Git verifies a signature against the list of trusted keys and does not compare the signer with the author line. That comparison is a policy, and you have to run it:

<!-- snippet: ch14b/spoof-signed/04-policy-check -->
```text
# Git verified a signature. It did not compare the signer with the author. A policy check does:
$ git log -3 --format='%h %G? %ae %GS' | awk '{ ok = ($2 == "G" && $3 == $4) ? "ok  " : "FAIL"; print ok, $0 }'
FAIL 4687f7f G asha@example.com you@example.com
FAIL bc6a046 N asha@example.com 
ok   4306257 G asha@example.com asha@example.com
```
<!-- /snippet -->

`git merge --verify-signatures` is not that policy either. It checks one commit:

<!-- snippet: ch14b/spoof-signed/05-merge-verify -->
```text
$ git switch -q -c integration main~2
$ git merge --verify-signatures --ff-only main~1
fatal: Commit bc6a046 does not have a GPG signature.
[exit status: 128]
# The option looks at one commit only: the tip of what is being merged.
$ git merge --verify-signatures --ff-only main
Commit 4687f7f has a good GPG signature by you@example.com
Updating 4306257..4687f7f
Fast-forward
 config/limits.yaml | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)
[exit status: 0]
$ git log -3 --format='%h  %G?  author=%ae  signer=%GS'
4687f7f  G  author=asha@example.com  signer=you@example.com
bc6a046  N  author=asha@example.com  signer=
4306257  G  author=asha@example.com  signer=asha@example.com
```
<!-- /snippet -->

The merge of an unsigned tip was refused. The merge of a signed tip was accepted, and it brought the unsigned commit underneath along: the manual says the option verifies "the tip commit of the side branch".

> **GitHub, not Git.** GitHub runs its own verification against the keys registered on accounts and labels commits "Verified", "Partially verified" (in vigilant mode) or "Unverified"; enforcement is the "require signed commits" rule (Phase 0 report; [about commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)). [Chapter 21B](ch21b-repository-security-incident-response.md) treats the platform side: how a signature is tied to an account, what vigilant mode adds for commits that name you as author, and a published demonstration of the spoofing shown here ([Gruntwork](https://www.gruntwork.io/blog/how-to-spoof-any-user-on-github-and-what-to-do-to-prevent-it)).

**In production.** The CTO's fourth question. If the commit is unsigned, Git cannot say who made it; the honest answer is "anyone with push access". If it is signed, Git can say which key signed it, and the investigation moves to the server's push log and the key's owner. The report separates three questions: who is displayed (email matching), who signed (a key), and what is enforced (rules).

## 14B.19 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| The same command behaves differently on two machines | `git config get --all --show-scope --show-origin <key>` on both; `git var` for editor, pager, identity | Set or unset the key in the scope that should own it | Keep local overrides rare and commented |
| A setting "does not take effect" | The key is misspelled, or a later scope or an environment variable overrides it | Correct the key; remove the override | Check keys against `git help --config` (Lab 5.4) |
| `fatal: bad config line N in file ...` on every command | File and line are in the message | Repair the line with a text editor | `git config set`, not hand edits |
| Work commits carry the personal address | `git config get --all --show-origin user.email` shows one value: the `includeIf` pattern lacks its slash, precedes `[user]`, or names a missing file | Fix the pattern; `git commit --amend --reset-author` for unpublished commits | `user.useConfigOnly=true`, no global default address |
| An alias misbehaves with an argument | `GIT_TRACE=1` shows the expansion | No hard-coded revisions; wrap shell aliases in a function | Test each alias with and without arguments |
| `git describe` fails in CI | `git rev-parse --is-shallow-repository`; `git tag` is empty | Fetch tags and full history in the versioning job | Fail the release job when `git describe --exact-match` fails |
| Two machines disagree about a tag | `git ls-remote origin 'refs/tags/<tag>^{}'` against `git rev-parse '<tag>^{commit}'` | Restore the published tag; release a new version | A server rule that makes release tags immutable |
| A deleted tag keeps coming back | Some clone still has it and pushes with `--tags` | Delete it there | Push single tags or `--follow-tags` |
| `error: gpg failed to sign the data` | `git config get gpg.format`; `user.signingKey`; run the signing program by hand | Configure the format and key you mean | Test signing after every key or machine change |
| A signed commit shows `No signature` | `gpg.ssh.allowedSignersFile` is unset or the file is missing | Configure the file | Ship the file with the signing setup |
| Old commits turn from `G` to `U` after a key rotation | The old key was removed from the allowed-signers file | List both keys (Lab 24.1) | Rotation adds, never replaces |
| A signed history contains a commit its named author never made | Signer and author differ: `git log --format='%h %G? %ae %GS'` | Treat as an incident (Chapter 21B) | Enforce signatures *and* compare signer with author |

## 14B.20 When not to use it, and dangerous edge cases

- **Configuration is not policy.** Nothing in a developer's configuration is enforced. Rules belong on the server and in CI.
- **No secrets in configuration.** A token in `remote.<name>.url` or in `http.extraHeader` is plain text, and `git config list` prints it into every bug report (Chapter 16).
- **`!` aliases, `core.sshCommand`, `core.pager`, `core.editor`, `core.hooksPath` and include paths execute or load things.** Whoever can write your configuration can run code as you. Never paste configuration you have not read.
- **`-c` values are visible in the process list of a shared machine.** `--config-env=<name>=<envvar>` reads the value from the environment instead ([git](https://git-scm.com/docs/git)).
- **Do not re-tag what has been published**, not even "before anyone noticed". A mirror, a cache or a build noticed.
- **`git push --tags` publishes everything**, including `wip-*` and bisect markers.
- **A lightweight tag is invisible to `git describe` and to `--follow-tags`.** Release tags are annotated.
- **A signature is evidence about a key.** A passphrase-less key on a laptop, a key copied into CI, or a shared team key reduce "signed by Asha" to "signed by something that had Asha's file".
- **`commit.gpgSign=true` without a working key blocks every commit**, including the one you need during an incident. Know `--no-gpg-sign`, and whether your server accepts the result.
- **Signatures do not survive rewrites.** A rebase, a squash or a history filter re-signs with the operator's key or with none (the Phase 0 report notes that git-filter-repo removes signatures).
- **`git merge --verify-signatures` checks only the tip.**

## 14B.21 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git config get`, `list`; `git var`; `git describe`; `git verify-commit`, `git verify-tag`, `git tag -v` | 🟢 SAFE | nothing | not needed | not needed |
| `git config set`, `unset`, `edit` | 🟡 CAUTION | one configuration file, which has no history | `git config get --show-origin <key>` | set the old value again; keep the global file under version control |
| `git tag <name>`, `-a`, `-s`; `git commit -S` | 🟢 SAFE | adds a ref or an object | `git log -1 <commit>` | `git tag -d <name>` while unpublished |
| `git tag -f`, `git tag -d` | 🟡 CAUTION | moves or deletes a local tag; no reflog | `git rev-parse <tag>`, and write the ID down | `git tag <name> <old-id>`; `git fsck` lists a dangling tag object |
| `git push origin <tag>`, `--follow-tags`, `--tags` | 🟡 CAUTION | creates tags on the server | `git push --dry-run` | none that is clean: others may have fetched |
| `git fetch --tags --force` | 🟡 CAUTION | overwrites local tags with the server's | `git fetch --tags --dry-run` | the old tag objects stay, dangling, until pruned |
| `git push --force origin <tag>` | 🔴 DANGEROUS | replaces a published tag | `git ls-remote --tags origin` | force the old tag object back from a clone that has it |
| `git push origin --delete <tag>` | 🔴 DANGEROUS | deletes a published tag | `git ls-remote --tags origin` | push it again from a clone that kept it |
| `git fetch --prune --prune-tags` | 🔴 DANGEROUS | deletes every local tag the remote lacks | add `--dry-run` | annotated tags: `git fsck`; lightweight: only the IDs in the command's output |

What the three 🔴 commands can destroy, and when they are appropriate:

- **`git push --force origin <tag>`** destroys the meaning of a release name for everyone who fetches later. Appropriate for putting a tag back at its *published* position (section 14B.11); a name that is meant to move should be a branch.
- **`git push origin --delete <tag>`** removes the only published name of a release commit, and the tag under a GitHub release. Appropriate for a tag pushed by mistake minutes ago, announced.
- **`git fetch --prune --prune-tags`** destroys private lightweight tags, which have no reflog and no object to find them by. Appropriate for a mirror or a CI cache that must equal the server.

## 14B.22 Version notes

> **Version note.** Older behavior: `git config --get`, `--add`, `--unset`, `-l`. Current behavior: `git config get`, `set`, `unset`, `list`, `edit`; the old modes are deprecated and still work. Since: Git 2.46 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.46.0.adoc)); `git config list` was declared the official spelling of `-l` in 2.54 ([release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.54.0.adoc)). Recommended: the subcommands, with a version check in scripts that run elsewhere.

> **Version note.** Older behavior: `includeIf` conditions are `gitdir`, `gitdir/i`, `onbranch` and `hasconfig:remote.*.url`; `gitdir` exists since Git 2.13 (git-config). Current behavior: Git 2.56 adds a condition on the location of the working tree (not run here; [release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc)). Recommended: `gitdir:` with a trailing slash, which every Git since 2.13 understands.

> **Version note.** Older behavior: signing meant GPG. Current behavior: `gpg.format` is `openpgp`, `x509` or `ssh`. Since: X.509 in Git 2.19, SSH in Git 2.34 ([gpg configuration](https://github.com/git/git/blob/v2.56.0/Documentation/config/gpg.adoc)). Recommended: SSH signing where it is accepted; the option names keep "gpg" for all three.

> **Version note.** Older behavior: `git init` creates `master`. Current behavior: still `master` on unconfigured Git 2.55, with a hint that Git 3.0 will use `main`; `init.defaultBranch` exists since Git 2.28 (Phase 0 report). Recommended: set it.

> **Version note.** Older behavior: `help.autocorrect=1` waited a tenth of a second before running the guess. Current behavior: `1` means run immediately. Since: Git 2.49. Recommended: `prompt`, or the default.

> **Unverified.** The minimum OpenSSH version for SSH signing was not established (Phase 0 report). The Git manual states only that `valid-after` and `valid-before` need OpenSSH 8.8; this machine runs 10.2.

## 14B.23 Practice

- **Module 5** ([lab manual](../lab-manual/m05-configuration.md)): 5.1 scopes and origins; 5.2 two identities with `includeIf`; 5.3 aliases; 5.4 your deliberate configuration, a worksheet.
- **Module 13** ([lab manual](../lab-manual/m13-tags-versions.md)): 13.1 three kinds of tag; 13.2 a moved tag between two clones; 13.3 describe and versions.
- **Module 24, local part** ([lab manual](../lab-manual/m24-signing-local.md)): 24.1 SSH signing locally; 24.2 a spoofed-author commit.
- Replay any transcript with `labs/run ch14b/<demo>`. A drill: in the sandbox left by `ch14b/includes`, make the identity depend on the branch with `onbranch:`.

## 14B.24 Interview questions

1. A setting is in the system, global and local files with three different values, and an environment variable also exists for it. Which wins, and which single command shows you?
2. Your `includeIf` rule for `~/work/` exists, yet a work repository commits with your personal address. Give four causes and the command that distinguishes them.
3. Why does Git not read configuration from a file committed in the repository? What do teams do instead?
4. What exactly runs when you type `git x foo` and `alias.x` is `!cmd $1`? How do you write it correctly?
5. Describe the objects and refs created by `git tag v1`, `git tag -a v1` and `git tag -s v1`. What does `v1^{}` resolve to in each case?
6. A release tag was force-moved yesterday. Who has which version of it today, how do you find out, and what is the lowest-risk repair?
7. `receive.denyNonFastForwards` is set on our Git server. Are our tags safe? How would you prove your answer?
8. `git describe` prints `v1.0.0-2-gc053f0d` on a laptop and fails in CI. Explain every part of the string and the failure.
9. What bytes does a commit signature cover? Name three things about a commit that it does not establish.
10. All commits on `main` show a good signature. Does that mean each was written by the person in its author field? What check is missing?
11. We rotate signing keys yearly. What happens to last year's signatures, and why do validity dates not help when a key is stolen?
12. Which Git settings would you standardize across a team, and which would you leave to each engineer?

## 14B.25 Sources

**Primary sources**

- [git-config](https://git-scm.com/docs/git-config), [git](https://git-scm.com/docs/git), [git-var](https://git-scm.com/docs/git-var), [gitcredentials](https://git-scm.com/docs/gitcredentials). The local copies (`git help -m <command>`) are the Git 2.55.0 text the transcripts were checked against.
- [git-tag](https://git-scm.com/docs/git-tag) (including "On Re-tagging"), [git-describe](https://git-scm.com/docs/git-describe), [git-for-each-ref](https://git-scm.com/docs/git-for-each-ref), [git-check-ref-format](https://git-scm.com/docs/git-check-ref-format), [git-push](https://git-scm.com/docs/git-push), [git-fetch](https://git-scm.com/docs/git-fetch), [gitworkflows](https://git-scm.com/docs/gitworkflows), [githooks](https://git-scm.com/docs/githooks).
- [gitformat-signature](https://git-scm.com/docs/gitformat-signature), [git-verify-commit](https://git-scm.com/docs/git-verify-commit), [git-verify-tag](https://git-scm.com/docs/git-verify-tag), [git-log](https://git-scm.com/docs/git-log) (pretty formats), [git-merge](https://git-scm.com/docs/git-merge), the [gpg configuration reference](https://github.com/git/git/blob/v2.56.0/Documentation/config/gpg.adoc), and [ssh-keygen(1)](https://man.openbsd.org/ssh-keygen), "ALLOWED SIGNERS".
- Git source at 2.55.0, read for behavior the manual does not state: [receive-pack.c](https://github.com/git/git/blob/v2.55.0/builtin/receive-pack.c) (the `receive.deny*` settings apply to `refs/heads/` only), [http.c](https://github.com/git/git/blob/v2.55.0/http.c) (`GIT_CURL_VERBOSE`), [editor.c](https://github.com/git/git/blob/v2.55.0/editor.c) (`VISUAL` and dumb terminals).
- Release notes [2.34](https://github.com/git/git/blob/master/Documentation/RelNotes/2.34.0.adoc), [2.45](https://github.com/git/git/blob/master/Documentation/RelNotes/2.45.0.adoc), [2.46](https://github.com/git/git/blob/master/Documentation/RelNotes/2.46.0.adoc), [2.49](https://github.com/git/git/blob/master/Documentation/RelNotes/2.49.0.adoc), [2.54](https://github.com/git/git/blob/master/Documentation/RelNotes/2.54.0.adoc), [2.56](https://github.com/git/git/blob/master/Documentation/RelNotes/2.56.0.adoc).
- [Semantic Versioning 2.0.0](https://semver.org/).
- GitHub Docs: [about commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification), [telling Git about your signing key](https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key), [about releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases), [associating text editors with Git](https://docs.github.com/en/get-started/git-basics/associating-text-editors-with-git).

**Secondary sources**

- Pro Git: [Git Configuration](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration), [Git Aliases](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases), [Tagging](https://git-scm.com/book/en/v2/Git-Basics-Tagging), [Signing Your Work](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work), [Environment Variables](https://git-scm.com/book/en/v2/Git-Internals-Environment-Variables). Caveats: legacy `git config` syntax, GPG only, `master`.
- Julia Evans, [Popular git config options](https://jvns.ca/blog/2024/02/16/popular-git-config-options/) (2024): a crowd-sourced list that overlaps the table in section 14B.5.
- Taylor Blau, [Highlights from Git 2.34](https://github.blog/open-source/git/highlights-from-git-2-34/): the introduction of SSH signing.
- Russ Cox, [the xz attack timeline](https://research.swtch.com/xz-timeline); Gruntwork, [How to spoof any user on GitHub](https://www.gruntwork.io/blog/how-to-spoof-any-user-on-github-and-what-to-do-to-prevent-it).

**Videos** (optional; assessments in the Phase 0 report rest on captions and chapter lists, not on full viewing)

- [So You Think You Know Git - FOSDEM 2024](https://www.youtube.com/watch?v=aolI_Rz0ZqY), Scott Chacon, 47 minutes: `includeIf` at 08:23, SSH signing and the "Verified" badge from 19:00. Caveats: a survey, not a deep dive; about one minute of product pitch.
- [Simplify signing Git commits and tags with SSH keys](https://www.youtube.com/watch?v=uhy_ojFqLg0), Andy Feller, Git Merge 2022 workshop, 56 minutes. Caveat: assessed from automatic captions and the description.
- [Tag, You're Leaked: Surviving the tj-actions Supply Chain Attack](https://www.youtube.com/watch?v=FxHIaRwc9c4), BSides PDX 2025, 24 minutes: what a moved tag costs at scale.

**Further reading**

- The "DISCUSSION" section of git-tag(1): three short essays on re-tagging, tag following and backdating.
