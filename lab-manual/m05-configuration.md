# Module 5 labs: Configuration, identity, and a professional setup

> **Baseline.** Git 2.55.0 on macOS. Every "Expected output" block is real output from the lab's replay script in `labs/ch14b/`. Read [Chapter 14B: Configuration, Aliases, Tags and Signing](../textbook/ch14b-config-tags-signing.md), sections 14B.1 to 14B.7, first.

## How to run these labs

Each lab has a setup script that builds its starting state in the hands-on sandbox, and a replay script that ran the whole lab with a fixed clock and produced the transcripts below. From the course root:

```bash
bash labs/ch14b/setup-05-1-scopes-origins.sh   # build the starting state (run again to start over)
labs/shell m05-1                               # open the isolated lab shell in that sandbox
labs/run ch14b/lab-05-1-scopes-origins         # optional: replay the whole lab and print its transcript
```

**The first step of every lab in this module.** The lab shell already isolates Git from your real configuration: it points `GIT_CONFIG_GLOBAL` at one file that all hands-on labs share. These labs change the global configuration on purpose, so each of them moves to a global file and a home directory of its own, inside the lab's sandbox:

```bash
export HOME="$PWD/home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"
```

After these two lines, `~` means the sandbox's `home` directory in this shell, `git config --global` writes to `home/.gitconfig`, and nothing you do can reach your real `~/.gitconfig` or leak into another lab. The effect ends when you type `exit`. If you open a second lab shell for the same lab, type the two lines again.

Differences between your terminal and the transcripts:

- `$LAB` in a transcript is the lab root. The replays ran in `$LAB/ch14b/lab-05-<k>-...`; your sandbox is `$LAB/hands-on/m05-<k>`. Paths differ in that one component.
- The commits that exist when you enter a sandbox have the IDs printed here, because the setup scripts use the fixed lab clock (7 September 2026). Commits you create have the real time and therefore other IDs, and `git var GIT_AUTHOR_IDENT` prints the current time.
- Lines such as `[exit status: 1]` are printed by the replay scripts. By hand, run `echo $?` after a command.
- Lines that start with `#` are notes from a script, not output of Git.
- The sandbox's global file contains `gc.reflogExpire=never` and `gc.reflogExpireUnreachable=never`. They belong to the lab (Chapter 1, section 1.7); Git's defaults are 90 and 30 days.

| Lab | Topic | Sandbox | Replay |
|---|---|---|---|
| 5.1 | Scopes and origins | `m05-1` | `ch14b/lab-05-1-scopes-origins` |
| 5.2 | Two identities with `includeIf` | `m05-2` | `ch14b/lab-05-2-two-identities` |
| 5.3 | Aliases | `m05-3` | `ch14b/lab-05-3-aliases` |
| 5.4 | Your deliberate configuration (a worksheet) | `m05-4` | `ch14b/lab-05-4-deliberate-config` |

Answers to the Questions of every lab are in [solutions/m05-lab-answers.md](../solutions/m05-lab-answers.md). Write your own answers first.

## Lab 5.1: Scopes and origins

### Objective

Say, for any setting, which file or variable it comes from and why that value wins. Set one key in every scope, watch the precedence, see what the environment overrides, and repair a configuration file that stops every Git command.

### Prerequisites

- Chapter 14B, sections 14B.2 and 14B.3.
- Chapter 1, section 1.7, for why the lab isolates configuration.

### Setup

```bash
bash labs/ch14b/setup-05-1-scopes-origins.sh
labs/shell m05-1
```

The sandbox contains `home/.gitconfig` and the repository `home/work/inference-gateway` with three commits.

### Commands

Step 1. Move into the sandbox's home, then list everything Git knows, with scope and origin.

```bash
export HOME="$PWD/home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"
cd ~/work/inference-gateway
git config list --show-scope --show-origin
```

Step 2. Set `pull.rebase` globally and locally. Predict what `get` prints before you run it.

```bash
git config set --global pull.rebase true
git config set pull.rebase false
git config get pull.rebase
git config get --all --show-scope --show-origin pull.rebase
```

Step 3. The command scope, in its two forms.

```bash
git -c pull.rebase=merges config get --show-scope --show-origin pull.rebase
GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=pull.rebase GIT_CONFIG_VALUE_0=interactive git config get --all --show-scope pull.rebase
```

Step 4. The system scope, with a stand-in file. The two variables apply to these commands only; your machine's system file is not read.

```bash
printf '[pull]\n\tff = only\n\trebase = interactive\n' > ~/etc-gitconfig
GIT_CONFIG_NOSYSTEM=0 GIT_CONFIG_SYSTEM=~/etc-gitconfig git config get --all --show-scope --show-origin --regexp "^pull\."
GIT_CONFIG_NOSYSTEM=0 GIT_CONFIG_SYSTEM=~/etc-gitconfig git config get --show-scope pull.rebase
```

Step 5. The worktree scope.

```bash
git config set extensions.worktreeConfig true
git config set --worktree core.sparseCheckout true
git config list --show-scope --show-origin | tail -4
```

Step 6. What the environment overrides.

```bash
git var GIT_AUTHOR_IDENT
GIT_AUTHOR_NAME="Night Shift" git var GIT_AUTHOR_IDENT
GIT_AUTHOR_NAME="Night Shift" git -c user.name="Day Shift" var GIT_AUTHOR_IDENT
git config set --global core.editor "code --wait"
(unset GIT_EDITOR; git var GIT_EDITOR)
(unset GIT_EDITOR; EDITOR=nano git var GIT_EDITOR)
GIT_EDITOR=vim git var GIT_EDITOR
```

### Expected output

<!-- snippet: ch14b/lab-05-1-scopes-origins/01-enter -->
```text
$ export HOME="$PWD/home"
$ export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"
$ cd ~/work/inference-gateway
$ git config list --show-scope --show-origin
global	file:$LAB/ch14b/lab-05-1-scopes-origins/home/.gitconfig	user.name=Lab User
global	file:$LAB/ch14b/lab-05-1-scopes-origins/home/.gitconfig	user.email=you@example.com
global	file:$LAB/ch14b/lab-05-1-scopes-origins/home/.gitconfig	init.defaultbranch=main
global	file:$LAB/ch14b/lab-05-1-scopes-origins/home/.gitconfig	gc.reflogexpire=never
global	file:$LAB/ch14b/lab-05-1-scopes-origins/home/.gitconfig	gc.reflogexpireunreachable=never
local	file:.git/config	core.repositoryformatversion=0
local	file:.git/config	core.filemode=true
local	file:.git/config	core.bare=false
local	file:.git/config	core.logallrefupdates=true
local	file:.git/config	core.ignorecase=true
local	file:.git/config	core.precomposeunicode=true
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-05-1-scopes-origins/02-two-scopes -->
```text
$ git config set --global pull.rebase true
$ git config set pull.rebase false
$ git config get pull.rebase
false
$ git config get --all --show-scope --show-origin pull.rebase
global	file:$LAB/ch14b/lab-05-1-scopes-origins/home/.gitconfig	true
local	file:.git/config	false
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-05-1-scopes-origins/03-command-scope -->
```text
$ git -c pull.rebase=merges config get --show-scope --show-origin pull.rebase
command	command line:	merges
$ GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=pull.rebase GIT_CONFIG_VALUE_0=interactive git config get --all --show-scope pull.rebase
global	true
local	false
command	interactive
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-05-1-scopes-origins/04-system-stand-in -->
```text
$ printf '[pull]\n\tff = only\n\trebase = interactive\n' > ~/etc-gitconfig
$ GIT_CONFIG_NOSYSTEM=0 GIT_CONFIG_SYSTEM=~/etc-gitconfig git config get --all --show-scope --show-origin --regexp "^pull\."
system	file:$LAB/ch14b/lab-05-1-scopes-origins/home/etc-gitconfig	only
system	file:$LAB/ch14b/lab-05-1-scopes-origins/home/etc-gitconfig	interactive
global	file:$LAB/ch14b/lab-05-1-scopes-origins/home/.gitconfig	true
local	file:.git/config	false
$ GIT_CONFIG_NOSYSTEM=0 GIT_CONFIG_SYSTEM=~/etc-gitconfig git config get --show-scope pull.rebase
local	false
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-05-1-scopes-origins/05-worktree-scope -->
```text
$ git config set extensions.worktreeConfig true
$ git config set --worktree core.sparseCheckout true
$ git config list --show-scope --show-origin | tail -4
local	file:.git/config	core.precomposeunicode=true
local	file:.git/config	pull.rebase=false
local	file:.git/config	extensions.worktreeconfig=true
worktree	file:.git/config.worktree	core.sparsecheckout=true
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-05-1-scopes-origins/06-environment -->
```text
$ git var GIT_AUTHOR_IDENT
Lab User <you@example.com> 1788756720 +0530
$ GIT_AUTHOR_NAME="Night Shift" git var GIT_AUTHOR_IDENT
Night Shift <you@example.com> 1788756780 +0530
$ GIT_AUTHOR_NAME="Night Shift" git -c user.name="Day Shift" var GIT_AUTHOR_IDENT
Night Shift <you@example.com> 1788756840 +0530
$ git config set --global core.editor "code --wait"
$ (unset GIT_EDITOR; git var GIT_EDITOR)
code --wait
$ (unset GIT_EDITOR; EDITOR=nano git var GIT_EDITOR)
code --wait
$ GIT_EDITOR=vim git var GIT_EDITOR
vim
```
<!-- /snippet -->

The timestamps in the `git var GIT_AUTHOR_IDENT` lines are the lab clock; yours show the current time.

### What happened internally

- `git config set --global` rewrote `home/.gitconfig`; `git config set` rewrote `.git/config`; `git config set --worktree` created `.git/config.worktree`, because the extension was enabled first. No object, ref, index entry or reflog line was written by any step.
- Every `git config get` re-read the files in the order system, global, local, worktree, command. For a single-valued key it printed the value read last. `--all` printed every value in that order.
- `-c` and the `GIT_CONFIG_COUNT` variables put values into the configuration of one process. Nothing was stored.
- `GIT_AUTHOR_NAME` is not configuration. Git consults it before `user.name`, whichever scope `user.name` comes from, which is why `-c user.name="Day Shift"` lost.

### Checkpoint

- `git config get pull.rebase` prints `false`, and `--show-scope` says `local`.
- `git config get --show-scope --show-origin core.sparseCheckout` names `.git/config.worktree`.
- `(unset GIT_EDITOR; git var GIT_EDITOR)` prints `code --wait`.

### Failure scenario

You add an alias by editing `.git/config` in a hurry and forget the closing bracket of the section header:

```bash
printf '[alias\n\tst = status -sb\n' >> .git/config
git status
git config list --global
git config edit
```

<!-- snippet: ch14b/lab-05-1-scopes-origins/07-failure -->
```text
$ printf '[alias\n\tst = status -sb\n' >> .git/config
$ git status
fatal: bad config line 12 in file .git/config
[exit status: 128]
$ git config list --global
fatal: bad config line 12 in file .git/config
[exit status: 128]
$ git config edit
fatal: bad config line 12 in file .git/config
[exit status: 128]
```
<!-- /snippet -->

Every command fails with the same message, including the ones that would help you look at the configuration.

### Recovery

The message names the file and the line. Git cannot repair it; a text tool can. Look at the end of the file, delete the broken section, and compare with the backup that `sed -i.bak` leaves:

```bash
tail -3 .git/config
sed -i.bak -e '/^\[alias$/,$d' .git/config
git status -sb
diff .git/config.bak .git/config
rm .git/config.bak
```

<!-- snippet: ch14b/lab-05-1-scopes-origins/08-recovery -->
```text
$ tail -3 .git/config
	worktreeConfig = true
[alias
	st = status -sb
$ sed -i.bak -e '/^\[alias$/,$d' .git/config
$ git status -sb
## main
$ diff .git/config.bak .git/config
12,13d11
< [alias
< 	st = status -sb
$ rm .git/config.bak
```
<!-- /snippet -->

By hand you would open the file in an editor and go to line 12. The `sed` command deletes from the line `[alias` to the end of the file, which is correct here only because the broken lines were the last ones.

### Verification

```bash
git config list --show-scope --show-origin
git config get --show-scope --show-origin pull.rebase
```

<!-- snippet: ch14b/lab-05-1-scopes-origins/09-verify -->
```text
$ git config list --show-scope --show-origin
global	file:$LAB/ch14b/lab-05-1-scopes-origins/home/.gitconfig	user.name=Lab User
global	file:$LAB/ch14b/lab-05-1-scopes-origins/home/.gitconfig	user.email=you@example.com
global	file:$LAB/ch14b/lab-05-1-scopes-origins/home/.gitconfig	init.defaultbranch=main
global	file:$LAB/ch14b/lab-05-1-scopes-origins/home/.gitconfig	gc.reflogexpire=never
global	file:$LAB/ch14b/lab-05-1-scopes-origins/home/.gitconfig	gc.reflogexpireunreachable=never
global	file:$LAB/ch14b/lab-05-1-scopes-origins/home/.gitconfig	pull.rebase=true
global	file:$LAB/ch14b/lab-05-1-scopes-origins/home/.gitconfig	core.editor=code --wait
local	file:.git/config	core.repositoryformatversion=0
local	file:.git/config	core.filemode=true
local	file:.git/config	core.bare=false
local	file:.git/config	core.logallrefupdates=true
local	file:.git/config	core.ignorecase=true
local	file:.git/config	core.precomposeunicode=true
local	file:.git/config	pull.rebase=false
local	file:.git/config	extensions.worktreeconfig=true
worktree	file:.git/config.worktree	core.sparsecheckout=true
$ git config get --show-scope --show-origin pull.rebase
local	file:.git/config	false
```
<!-- /snippet -->

Three scopes are visible, and nothing is left of the broken section.

### Questions

1. `git config get --all --show-scope pull.rebase` printed several lines. Which line is "the" value, and what rule decides it?
2. In step 4 the stand-in system file set `pull.ff=only` and `pull.rebase=interactive`. While that file was being read, which of its two values was in force, and why not both?
3. Why did `GIT_AUTHOR_NAME="Night Shift" git -c user.name="Day Shift" var GIT_AUTHOR_IDENT` print "Night Shift", although `-c` is the scope that is read last?
4. Had you run `git config set --worktree core.sparseCheckout true` *before* enabling the extension, where would the value have gone? How would you have noticed?
5. In the failure scenario even `git config list --global` failed, although the global file was fine. Why? Name a directory in which that command would have worked.

## Lab 5.2: Two identities with `includeIf`

### Objective

Give every repository under `~/work` a work address and every other repository a personal one, with one conditional include. Prove it with commits. Then break the rule the way it usually breaks, diagnose it from the configuration, and repair both the rule and the commit it spoiled.

### Prerequisites

- Chapter 14B, section 14B.4.
- Chapter 6, section 6.13, for `git commit --amend --reset-author` and `user.useConfigOnly`.

### Setup

```bash
bash labs/ch14b/setup-05-2-two-identities.sh
labs/shell m05-2
```

The sandbox contains two repositories: `home/work/inference-gateway` (three commits) and `home/oss/evalkit` (one commit).

### Commands

Step 1. Enter the sandbox's home. Both repositories use the same address.

```bash
export HOME="$PWD/home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"
git -C ~/work/inference-gateway config get --show-origin user.email
git -C ~/oss/evalkit config get --show-origin user.email
```

Step 2. Write the work identity into its own file and include it for everything under `~/work/`. The quotes keep the shell from expanding `~`: Git must see it.

```bash
printf '[user]\n\temail = lab.user@corp.example\n' > ~/.gitconfig-work
git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'
tail -2 ~/.gitconfig
```

Step 3. Ask each repository who you are.

```bash
cd ~/work/inference-gateway
git config get --all --show-scope --show-origin user.email
git var GIT_AUTHOR_IDENT
cd ~/oss/evalkit
git config get --all --show-scope --show-origin user.email
git var GIT_AUTHOR_IDENT
```

Step 4. Commit in both.

```bash
cd ~/work/inference-gateway
printf 'timeout_seconds: 30\n' >> config/limits.yaml
git commit -q -am "Add request timeout"
git log -2 --format='%an <%ae>  %s'
cd ~/oss/evalkit
printf '\nRun: python -m evalkit\n' >> README.md
git commit -q -am "Document how to run"
git log -2 --format='%an <%ae>  %s'
```

Step 5. A diagnostic that misleads.

```bash
cd ~/work/inference-gateway
git config get --global user.email
git config get --global --includes user.email
```

### Expected output

<!-- snippet: ch14b/lab-05-2-two-identities/01-before -->
```text
$ export HOME="$PWD/home"
$ export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"
$ git -C ~/work/inference-gateway config get --show-origin user.email
file:$LAB/ch14b/lab-05-2-two-identities/home/.gitconfig	you@example.com
$ git -C ~/oss/evalkit config get --show-origin user.email
file:$LAB/ch14b/lab-05-2-two-identities/home/.gitconfig	you@example.com
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-05-2-two-identities/02-include-if -->
```text
$ printf '[user]\n\temail = lab.user@corp.example\n' > ~/.gitconfig-work
$ git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'
$ tail -2 ~/.gitconfig
[includeIf "gitdir:~/work/"]
	path = ~/.gitconfig-work
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-05-2-two-identities/03-effect -->
```text
$ cd ~/work/inference-gateway
$ git config get --all --show-scope --show-origin user.email
global	file:$LAB/ch14b/lab-05-2-two-identities/home/.gitconfig	you@example.com
global	file:$LAB/ch14b/lab-05-2-two-identities/home/.gitconfig-work	lab.user@corp.example
$ git var GIT_AUTHOR_IDENT
Lab User <lab.user@corp.example> 1788756420 +0530
$ cd ~/oss/evalkit
$ git config get --all --show-scope --show-origin user.email
global	file:$LAB/ch14b/lab-05-2-two-identities/home/.gitconfig	you@example.com
$ git var GIT_AUTHOR_IDENT
Lab User <you@example.com> 1788756600 +0530
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-05-2-two-identities/04-commits -->
```text
$ cd ~/work/inference-gateway
$ printf 'timeout_seconds: 30\n' >> config/limits.yaml
$ git commit -q -am "Add request timeout"
$ git log -2 --format='%an <%ae>  %s'
Lab User <lab.user@corp.example>  Add request timeout
Lab User <you@example.com>  Add rate limits
$ cd ~/oss/evalkit
$ printf '\nRun: python -m evalkit\n' >> README.md
$ git commit -q -am "Document how to run"
$ git log -2 --format='%an <%ae>  %s'
Lab User <you@example.com>  Document how to run
Lab User <you@example.com>  Add README
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-05-2-two-identities/05-includes-flag -->
```text
$ cd ~/work/inference-gateway
$ git config get --global user.email
you@example.com
$ git config get --global --includes user.email
lab.user@corp.example
```
<!-- /snippet -->

### What happened internally

- `git config set --global 'includeIf.gitdir:~/work/.path' ...` appended a section `[includeIf "gitdir:~/work/"]` with one `path` line to `home/.gitconfig`. The key has three parts: section `includeIf`, subsection `gitdir:~/work/`, variable `path`.
- When a command runs inside `~/work/inference-gateway`, Git compares the location of that repository's `.git` directory with the pattern. `~/` becomes `$HOME/`, and the trailing `/` becomes `/**`. The pattern matches, so the included file is read at that point of the global file, after `[user]`, and its `user.email` is the value read last.
- In `~/oss/evalkit` the pattern does not match and `~/.gitconfig-work` is not opened.
- Each commit copied the identity that was in force at that moment into its `author` and `committer` lines. The older commits were not touched: they were created by the setup script with the address `you@example.com`.
- `--global` restricts the query to one scope and, as a side effect, switches include processing off; `--includes` switches it back on.

### Checkpoint

- `git -C ~/work/inference-gateway config get --show-origin user.email` names `.gitconfig-work`.
- The newest commit in `inference-gateway` has `lab.user@corp.example`; the newest commit in `evalkit` has `you@example.com`.

### Failure scenario

Someone tidies the global file and drops the trailing slash from the pattern. Nothing complains. The next commit in the work repository:

```bash
git config unset --global 'includeIf.gitdir:~/work/.path'
git config set --global 'includeIf.gitdir:~/work.path' '~/.gitconfig-work'
printf 'max_retries: 2\n' >> config/limits.yaml
git commit -q -am "Add retry limit"
git log -2 --format='%an <%ae>  %s'
```

<!-- snippet: ch14b/lab-05-2-two-identities/06-failure -->
```text
# Someone tidies the global file and drops the trailing slash from the pattern.
$ git config unset --global 'includeIf.gitdir:~/work/.path'
$ git config set --global 'includeIf.gitdir:~/work.path' '~/.gitconfig-work'
$ printf 'max_retries: 2\n' >> config/limits.yaml
$ git commit -q -am "Add retry limit"
$ git log -2 --format='%an <%ae>  %s'
Lab User <you@example.com>  Add retry limit
Lab User <lab.user@corp.example>  Add request timeout
```
<!-- /snippet -->

The new commit carries the personal address. Diagnose from the configuration, not from memory:

```bash
git config get --all --show-origin user.email
git config get --global --all --show-names --regexp "^includeif"
git rev-parse --absolute-git-dir
```

<!-- snippet: ch14b/lab-05-2-two-identities/07-diagnose -->
```text
$ git config get --all --show-origin user.email
file:$LAB/ch14b/lab-05-2-two-identities/home/.gitconfig	you@example.com
$ git config get --global --all --show-names --regexp "^includeif"
includeif.gitdir:~/work.path ~/.gitconfig-work
$ git rev-parse --absolute-git-dir
$LAB/ch14b/lab-05-2-two-identities/home/work/inference-gateway/.git
```
<!-- /snippet -->

Only one value is in force, so the include is not being read. The pattern is `gitdir:~/work`, and the repository's `.git` directory is `.../home/work/inference-gateway/.git`: without the slash the pattern would match only a `.git` directory located exactly at `~/work`.

### Recovery

Repair the pattern, confirm the identity, and replace the unpublished commit:

```bash
git config unset --global 'includeIf.gitdir:~/work.path'
git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'
git var GIT_AUTHOR_IDENT
git commit -q --amend --no-edit --reset-author
git log -2 --format='%an <%ae>  %s'
```

<!-- snippet: ch14b/lab-05-2-two-identities/08-recovery -->
```text
$ git config unset --global 'includeIf.gitdir:~/work.path'
$ git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'
$ git var GIT_AUTHOR_IDENT
Lab User <lab.user@corp.example> 1788757920 +0530
# The wrong commit is unpublished, so it can be replaced.
$ git commit -q --amend --no-edit --reset-author
$ git log -2 --format='%an <%ae>  %s'
Lab User <lab.user@corp.example>  Add retry limit
Lab User <lab.user@corp.example>  Add request timeout
```
<!-- /snippet -->

`--reset-author` makes the amended commit take author and committer from the current configuration. This is a rewrite: do it only while the commit is unpublished (Chapter 6, section 6.7).

### Verification

```bash
git -C ~/work/inference-gateway config get --show-origin user.email
git -C ~/oss/evalkit config get --show-origin user.email
git -C ~/work/inference-gateway log --format='%ae' | sort | uniq -c | sed 's/^ *//'
```

<!-- snippet: ch14b/lab-05-2-two-identities/09-verify -->
```text
$ git -C ~/work/inference-gateway config get --show-origin user.email
file:$LAB/ch14b/lab-05-2-two-identities/home/.gitconfig-work	lab.user@corp.example
$ git -C ~/oss/evalkit config get --show-origin user.email
file:$LAB/ch14b/lab-05-2-two-identities/home/.gitconfig	you@example.com
$ git -C ~/work/inference-gateway log --format='%ae' | sort | uniq -c | sed 's/^ *//'
2 lab.user@corp.example
3 you@example.com
```
<!-- /snippet -->

Two commits with the work address, and the three older ones that the setup script made before the rule existed.

### Questions

1. `git config get --all --show-scope --show-origin user.email` printed two lines in the work repository, both with scope `global`. Why two, why both global, and why does the second win?
2. You typed the pattern in single quotes. What would have been stored if you had written `"includeIf.gitdir:$HOME/work/.path"` instead, and what would be worse about it?
3. Suppose the global file listed `[includeIf "gitdir:~/work/"]` *before* the `[user]` section. Which address would the work repository use, and which command shows the reason?
4. You run `git init ~/work/new-service` and immediately `git -C ~/work/new-service config get user.email`. Which address is printed? And which one if you run `git config get user.email` in `~/work` itself?
5. The three older commits in the work repository still carry `you@example.com`. Under what circumstances would you rewrite them, and under what circumstances would you leave them?

## Lab 5.3: Aliases

### Objective

Define the five aliases `st`, `lg`, `last`, `unstage` and `amend`, run each, and be able to say exactly which Git command every one of them executes. Find the trap in `last`, break a shell alias with an argument, and repair it.

### Prerequisites

- Chapter 14B, section 14B.6.
- Chapters 4, 5 and 6 for `status`, `restore --staged` and `commit --amend`.

### Setup

```bash
bash labs/ch14b/setup-05-3-aliases.sh
labs/shell m05-3
```

The sandbox contains `home/work/inference-gateway` with four commits on `main` and one more on `feature/fallback-route`.

### Commands

Step 1. Enter the sandbox's home and define the aliases.

```bash
export HOME="$PWD/home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"
cd ~/work/inference-gateway
git config set --global alias.st 'status -sb'
git config set --global alias.lg 'log --graph --decorate --oneline --all'
git config set --global alias.last 'log -1 --stat HEAD'
git config set --global alias.unstage 'restore --staged --'
git config set --global alias.amend 'commit --amend --no-edit'
git config get --all --show-names --regexp "^alias\."
```

Step 2. The three that only read.

```bash
git st
git lg
git last
```

Step 3. The two that change state. Predict the status output after `git unstage notes.txt`, and what `git amend` will include.

```bash
printf 'burst: 20\n' >> config/limits.yaml
printf 'scratch\n' > notes.txt
git add .
git st
git unstage notes.txt
git st
git amend
git reflog -2
```

Step 4. Make the expansion visible. `grep` keeps the two trace lines that matter.

```bash
GIT_TRACE=1 git st 2>&1 | grep -E -o '(alias expansion|built-in): .*'
GIT_TRACE=1 git lg -2 2>&1 | grep -E -o '(alias expansion|built-in): .*'
```

Step 5. Ask `last` about another branch. Predict the commit it shows.

```bash
git last --format="%h %s" feature/fallback-route
GIT_TRACE=1 git last --format='%h %s' feature/fallback-route 2>&1 | grep -E -o 'built-in: .*'
git config set --global alias.last 'log -1 --stat'
git last --format="%h %s" feature/fallback-route
```

### Expected output

<!-- snippet: ch14b/lab-05-3-aliases/01-define -->
```text
$ export HOME="$PWD/home"
$ export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"
$ cd ~/work/inference-gateway
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

<!-- snippet: ch14b/lab-05-3-aliases/02-read-only -->
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

<!-- snippet: ch14b/lab-05-3-aliases/03-unstage-amend -->
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
$ git amend
[main e8f84c9] Raise the rate limit
 Date: Mon Sep 7 10:09:00 2026 +0530
 1 file changed, 2 insertions(+), 1 deletion(-)
$ git reflog -2
e8f84c9 HEAD@{0}: commit (amend): Raise the rate limit
1adfaa7 HEAD@{1}: commit: Raise the rate limit
```
<!-- /snippet -->

Your amended commit has another ID than the one printed, because its committer date is the real time. Its `Date:` line matches: that is the author date, which the amend kept.

<!-- snippet: ch14b/lab-05-3-aliases/04-expansion -->
```text
$ GIT_TRACE=1 git st 2>&1 | grep -E -o '(alias expansion|built-in): .*'
alias expansion: st => status -sb
built-in: git status -sb
$ GIT_TRACE=1 git lg -2 2>&1 | grep -E -o '(alias expansion|built-in): .*'
alias expansion: lg => log --graph --decorate --oneline --all
built-in: git log --graph --decorate --oneline --all -2
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-05-3-aliases/05-last-trap -->
```text
$ git last --format="%h %s" feature/fallback-route
e8f84c9 Raise the rate limit

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

### What happened internally

- Each `git config set --global alias.<name>` added one line to the `[alias]` section of `home/.gitconfig`. Nothing in the repository changed.
- `git st`: Git found no command named `st`, looked up `alias.st`, replaced the word by `status -sb`, and ran the built-in `status`. Arguments after the alias name are appended to the expansion: `git lg -2` ran `git log --graph --decorate --oneline --all -2`.
- `git unstage notes.txt` ran `git restore --staged -- notes.txt`: the index entry for `notes.txt` was removed (the file is not in HEAD), the file stayed in the working tree.
- `git amend` ran `git commit --amend --no-edit`: a new commit object with the same parent and message and a tree that includes the staged change to `config/limits.yaml`; `refs/heads/main` moved to it; the reflog gained a `commit (amend)` line and still names the old commit.
- With `HEAD` hard-coded in the alias, `git last ... feature/fallback-route` ran `git log -1 --stat HEAD ... feature/fallback-route`: one commit, the newest reachable from either revision.

### Checkpoint

- `git config get alias.last` prints `log -1 --stat`.
- `git st` shows `?? notes.txt` and no staged changes.
- `git reflog -2` shows a `commit (amend)` entry above the original commit.

### Failure scenario

You want an alias that lists the first files of any revision and write it as a shell alias with `$1`:

```bash
git config set --global alias.tracked '!git ls-tree -r --name-only $1 | head -2'
git tracked HEAD
GIT_TRACE=1 git tracked HEAD 2>&1 | grep -o 'start_command: .*'
```

<!-- snippet: ch14b/lab-05-3-aliases/06-failure -->
```text
$ git config set --global alias.tracked '!git ls-tree -r --name-only $1 | head -2'
$ git tracked HEAD
head: HEAD: No such file or directory
[exit status: 1]
$ GIT_TRACE=1 git tracked HEAD 2>&1 | grep -o 'start_command: .*'
start_command: /bin/sh -c 'git ls-tree -r --name-only $1 | head -2 "$@"' 'git ls-tree -r --name-only $1 | head -2' HEAD
```
<!-- /snippet -->

`head` complains about a file named `HEAD`. The trace shows why: Git runs the alias through `sh -c` with `"$@"` appended, so the argument was used once as `$1` and a second time at the end of the pipeline.

### Recovery

Wrap the commands in a function that consumes the arguments, and give the argument a default:

```bash
git config set --global alias.tracked '!f() { git ls-tree -r --name-only "${1:-HEAD}" | head -2; }; f'
git tracked
git tracked feature/fallback-route
cd gateway
git tracked
git config set --global alias.top '!pwd'
git top
cd ..
```

<!-- snippet: ch14b/lab-05-3-aliases/07-recovery -->
```text
$ git config set --global alias.tracked '!f() { git ls-tree -r --name-only "${1:-HEAD}" | head -2; }; f'
$ git tracked
README.md
config/limits.yaml
$ git tracked feature/fallback-route
README.md
config/limits.yaml
$ cd gateway
$ git tracked
README.md
config/limits.yaml
$ git config set --global alias.top '!pwd'
$ git top
$LAB/ch14b/lab-05-3-aliases/home/work/inference-gateway
$ cd ..
```
<!-- /snippet -->

`git tracked` printed the same two paths from inside `gateway/`, and `git top` printed the top-level directory: a shell alias always runs from the top of the working tree.

### Verification

```bash
git config get --all --show-names --show-origin --regexp "^alias\."
git st
```

<!-- snippet: ch14b/lab-05-3-aliases/08-verify -->
```text
$ git config get --all --show-names --show-origin --regexp "^alias\."
file:$LAB/ch14b/lab-05-3-aliases/home/.gitconfig	alias.st status -sb
file:$LAB/ch14b/lab-05-3-aliases/home/.gitconfig	alias.lg log --graph --decorate --oneline --all
file:$LAB/ch14b/lab-05-3-aliases/home/.gitconfig	alias.last log -1 --stat
file:$LAB/ch14b/lab-05-3-aliases/home/.gitconfig	alias.unstage restore --staged --
file:$LAB/ch14b/lab-05-3-aliases/home/.gitconfig	alias.amend commit --amend --no-edit
file:$LAB/ch14b/lab-05-3-aliases/home/.gitconfig	alias.tracked !f() { git ls-tree -r --name-only "${1:-HEAD}" | head -2; }; f
file:$LAB/ch14b/lab-05-3-aliases/home/.gitconfig	alias.top !pwd
$ git st
## main
?? notes.txt
```
<!-- /snippet -->

Seven aliases, all in the sandbox's global file, each of which you can now expand in your head.

### Questions

1. Write out the full Git command line that `git lg -2 main` runs. Which part came from you and which from the alias?
2. Why did `git last feature/fallback-route` show a commit of `main` while the alias still contained `HEAD`? Describe what `git log -1 A B` selects.
3. `unstage` ends in `--`. Construct a file name for which `git restore --staged <name>` and `git restore --staged -- <name>` behave differently.
4. `git amend` rewrote a commit with two words. Which line of which file lets you get the old commit back, and what is the command?
5. You define `alias.log = log --oneline` hoping to change the default format of `git log`. What happens, and why is that the right behavior for a tool that scripts depend on?

## Lab 5.4: Your deliberate configuration (a worksheet)

### Objective

Decide each of the settings in the table of Chapter 14B, section 14B.5, write your decisions into a global file with the reason beside each line, test three of them, and catch a misspelled key that Git accepted. The result is a file you can defend line by line, built in the sandbox. Copying it to your real machine afterwards is your decision and is not part of the lab.

### Prerequisites

- Chapter 14B, sections 14B.3 and 14B.5.
- Chapter 12, sections 12.5 and 12.6, for upstreams and `git pull`.

### Setup

```bash
bash labs/ch14b/setup-05-4-deliberate-config.sh
labs/shell m05-4
```

The sandbox contains a bare repository `server/inference-gateway.git`, your clone `you/inference-gateway`, and `home/.gitconfig`.

**The worksheet.** Fill this in before you type anything. "Default" is what Git 2.55 does when the key is not set (from the manual; "unset" means the manual states no value). The replay below shows one defensible set of answers, not the answer.

| Setting | Default | Your value | Your reason | Downside you accept | Global or per repository | Personal or team |
|---|---|---|---|---|---|---|
| `user.name`, `user.email` | none; Git guesses from the login name unless `user.useConfigOnly` is true | | | | | |
| `init.defaultBranch` | unset: `master`, with a hint | | | | | |
| `pull.rebase` | unset: a diverged pull stops | | | | | |
| `pull.ff` | unset | | | | | |
| `push.default` | `simple` | | | | | |
| `push.autoSetupRemote` | false | | | | | |
| `fetch.prune` | false | | | | | |
| `merge.conflictStyle` | `merge` | | | | | |
| `rebase.autoSquash` | false | | | | | |
| `rebase.autoStash` | false | | | | | |
| `rebase.updateRefs` | false | | | | | |
| `rerere.enabled` | unset: off until an `rr-cache` directory exists | | | | | |
| `diff.algorithm` | `myers` | | | | | |
| `diff.colorMoved` | unset: moved lines are not marked | | | | | |
| `core.editor` | unset: `VISUAL`, `EDITOR`, then `vi` | | | | | |
| `core.autocrlf` | unset | | | | | |
| `core.excludesFile` | `$XDG_CONFIG_HOME/git/ignore` | | | | | |
| `commit.gpgSign` | unset: no signing | | | | | |
| `help.autocorrect` | show the suggestion, run nothing | | | | | |

### Commands

Step 1. Enter the sandbox's home and look at the file you start from.

```bash
export HOME="$PWD/home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"
cat ~/.gitconfig
```

Step 2. Write your decisions, one `git config set --global` per line, with `--comment` for the reason. The replay used these; use your own worksheet.

```bash
git config set --global --comment "refuse to guess an identity" user.useConfigOnly true
git config set --global --comment "never integrate by accident" pull.ff only
git config set --global --comment "first push sets the upstream" push.autoSetupRemote true
git config set --global --comment "forget branches deleted on the server" fetch.prune true
git config set --global --comment "show the common ancestor in conflicts" merge.conflictStyle zdiff3
git config set --global --comment "fixup! commits find their place" rebase.autoSquash true
git config set --global --comment "stacked branches move together" rebase.updateRefs true
git config set --global --comment "remember conflict resolutions" rerere.enabled true
git config set --global --comment "moved code reads as a move" diff.algorithm histogram
git config set --global diff.colorMoved default
git config set --global --comment "show the suggestion, run nothing" help.autocorrect prompt
git config set --global core.excludesFile "~/.config/git/ignore"
cat ~/.gitconfig
```

Step 3. Test `push.autoSetupRemote`: push a new branch without `-u`.

```bash
cd you/inference-gateway
git switch -q -c feature/token-budget
printf 'daily_token_budget: 2000000\n' >> config/limits.yaml
git commit -q -am "Add daily token budget"
git push
git status -sb
```

Step 4. Test `pull.ff=only`: make `main` diverge, then pull.

```bash
git switch -q main
git clone -q ../../server/inference-gateway.git ../../other
git -C ../../other commit -q --allow-empty -m "Server-side change"
git -C ../../other push -q
git commit -q --allow-empty -m "Local change"
git pull
git status -sb
```

Step 5. Test `core.excludesFile`.

```bash
mkdir -p ~/.config/git
printf '.DS_Store\n.idea/\n*.swp\n' > ~/.config/git/ignore
touch .DS_Store
git status --short
git check-ignore -v .DS_Store
```

### Expected output

<!-- snippet: ch14b/lab-05-4-deliberate-config/01-start -->
```text
$ export HOME="$PWD/home"
$ export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"
$ cat ~/.gitconfig
[user]
	name = Lab User
	email = you@example.com
[init]
	defaultBranch = main
[gc]
	reflogExpire = never
	reflogExpireUnreachable = never
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-05-4-deliberate-config/02-decisions -->
```text
$ git config set --global --comment "refuse to guess an identity" user.useConfigOnly true
$ git config set --global --comment "never integrate by accident" pull.ff only
$ git config set --global --comment "first push sets the upstream" push.autoSetupRemote true
$ git config set --global --comment "forget branches deleted on the server" fetch.prune true
$ git config set --global --comment "show the common ancestor in conflicts" merge.conflictStyle zdiff3
$ git config set --global --comment "fixup! commits find their place" rebase.autoSquash true
$ git config set --global --comment "stacked branches move together" rebase.updateRefs true
$ git config set --global --comment "remember conflict resolutions" rerere.enabled true
$ git config set --global --comment "moved code reads as a move" diff.algorithm histogram
$ git config set --global diff.colorMoved default
$ git config set --global --comment "show the suggestion, run nothing" help.autocorrect prompt
$ git config set --global core.excludesFile "~/.config/git/ignore"
```
<!-- /snippet -->

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

<!-- snippet: ch14b/lab-05-4-deliberate-config/04-test-push -->
```text
$ cd you/inference-gateway
$ git switch -q -c feature/token-budget
$ printf 'daily_token_budget: 2000000\n' >> config/limits.yaml
$ git commit -q -am "Add daily token budget"
$ git push
To ../../server/inference-gateway.git
 * [new branch]      feature/token-budget -> feature/token-budget
branch 'feature/token-budget' set up to track 'origin/feature/token-budget'.
$ git status -sb
## feature/token-budget...origin/feature/token-budget
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-05-4-deliberate-config/05-test-pull -->
```text
# Make main diverge: one commit on the server that you do not have, one local commit.
$ git switch -q main
$ git clone -q ../../server/inference-gateway.git ../../other
$ git -C ../../other commit -q --allow-empty -m "Server-side change"
$ git -C ../../other push -q
$ git commit -q --allow-empty -m "Local change"
$ git pull
From ../../server/inference-gateway
   d20ef7a..ae873ce  main       -> origin/main
hint: Diverging branches can't be fast-forwarded, you need to either:
hint:
hint: 	git merge --no-ff
hint:
hint: or:
hint:
hint: 	git rebase
hint:
hint: Disable this message with "git config set advice.diverging false"
fatal: Not possible to fast-forward, aborting.
[exit status: 128]
$ git status -sb
## main...origin/main [ahead 1, behind 1]
```
<!-- /snippet -->

<!-- snippet: ch14b/lab-05-4-deliberate-config/06-test-ignore -->
```text
$ mkdir -p ~/.config/git
$ printf '.DS_Store\n.idea/\n*.swp\n' > ~/.config/git/ignore
$ touch .DS_Store
$ git status --short
$ git check-ignore -v .DS_Store
$LAB/ch14b/lab-05-4-deliberate-config/home/.config/git/ignore:1:.DS_Store	.DS_Store
```
<!-- /snippet -->

### What happened internally

- Twelve `git config set --global` commands edited one file. `--comment` put ` # <text>` after the value; Git ignores it when reading.
- `git push` on a branch without an upstream: because of `push.autoSetupRemote`, Git behaved as if you had typed `git push -u origin feature/token-budget`. It created `refs/heads/feature/token-budget` on the server, your `refs/remotes/origin/feature/token-budget`, and the two `branch.feature/token-budget.*` lines in `.git/config`.
- `git pull` fetched (the `From ...` line shows `origin/main` moving), found that `main` and `origin/main` had diverged, and stopped because `pull.ff=only` permits only a fast-forward. Your branch, index and working tree were not changed; `git status -sb` shows `[ahead 1, behind 1]`.
- `git status --short` printed nothing although `.DS_Store` exists: the pattern in the file named by `core.excludesFile` ignored it, and `git check-ignore -v` names the file, the line and the pattern.

### Checkpoint

- Every line you added to `~/.gitconfig` has a reason you can say aloud.
- `git status -sb` on `feature/token-budget` shows an upstream; on `main` it shows `[ahead 1, behind 1]`.
- `git check-ignore -v .DS_Store` names your personal ignore file.

### Failure scenario

One more decision, typed too fast:

```bash
git config set --global pull.rebsae true
git config get pull.rebase
```

Git accepted the key and nothing changed. Build a check: every key in your global file that this version of Git does not know.

```bash
git config list --global --name-only | sort -u > ~/mine.txt
git help --config | tr 'A-Z' 'a-z' | sort -u > ~/known.txt
comm -23 ~/mine.txt ~/known.txt
```

<!-- snippet: ch14b/lab-05-4-deliberate-config/07-failure -->
```text
$ git config set --global pull.rebsae true
$ git config get pull.rebase
[exit status: 1]
$ git config list --global --name-only | sort -u > ~/mine.txt
$ git help --config | tr 'A-Z' 'a-z' | sort -u > ~/known.txt
$ comm -23 ~/mine.txt ~/known.txt
pull.rebsae
```
<!-- /snippet -->

`comm -23` prints the lines that are only in the first file. Keys with a part you choose yourself (`alias.st`, `branch.main.remote`, `includeIf...path`, `credential.<url>.username`) are listed in `git help --config` with a placeholder, so they will show up here as well; read the output, do not automate a verdict.

### Recovery

```bash
git config unset --global pull.rebsae
git config set --global --comment "linear local history; revisit per team" pull.rebase true
git config list --global --name-only | sort -u > ~/mine.txt
comm -23 ~/mine.txt ~/known.txt
```

<!-- snippet: ch14b/lab-05-4-deliberate-config/08-recovery -->
```text
$ git config unset --global pull.rebsae
$ git config set --global --comment "linear local history; revisit per team" pull.rebase true
$ git config list --global --name-only | sort -u > ~/mine.txt
$ comm -23 ~/mine.txt ~/known.txt
[exit status: 0]
```
<!-- /snippet -->

No output: every key is known. Note what the corrected setting now does together with `pull.ff=only` (Question 3).

### Verification

```bash
git config list --global --show-origin | cut -f2
cat ~/.gitconfig
```

<!-- snippet: ch14b/lab-05-4-deliberate-config/09-verify -->
```text
$ git config list --global --show-origin | cut -f2
user.name=Lab User
user.email=you@example.com
user.useconfigonly=true
init.defaultbranch=main
gc.reflogexpire=never
gc.reflogexpireunreachable=never
pull.ff=only
pull.rebase=true
push.autosetupremote=true
fetch.prune=true
merge.conflictstyle=zdiff3
rebase.autosquash=true
rebase.updaterefs=true
rerere.enabled=true
diff.algorithm=histogram
diff.colormoved=default
help.autocorrect=prompt
core.excludesfile=~/.config/git/ignore
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
	rebase = true # linear local history; revisit per team
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

Compare the file with your worksheet. If a line is there and you cannot say why, remove it.

### Questions

1. Which of your settings would you put into a script that sets up every new team member's machine, and which would you leave out? Give the principle, not the list.
2. `push.autoSetupRemote` saved you one flag. Describe a situation in which that convenience publishes something you did not intend.
3. The replay ends with both `pull.ff=only` and `pull.rebase=true` in the global file. What does `git pull` do on a diverged branch now? Which chapter's experiment tells you, and how would you confirm it in this sandbox?
4. Git stored `pull.rebsae` without complaint. Why is "reject unknown keys" not a fix that the Git project could adopt?
5. Your worksheet has a column "Global or per repository". Name one setting from the table that you would deliberately set per repository, and say why.
