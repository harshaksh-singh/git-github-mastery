# V028: Conditional includes, the settings to decide deliberately, aliases, and environment variables for diagnosis

- **Part.** 1: Foundations
- **Module.** 5
- **Planned minutes.** 26
- **Prerequisites.** V027
- **Textbook sections.** [Chapter 14B: Configuration, Aliases, Tags and Signing](../../textbook/ch14b-config-tags-signing.md), sections 14B.4 to 14B.7
- **Demo scripts.** `labs/ch14b/includes.sh`, `labs/ch14b/settings.sh`, `labs/ch14b/aliases.sh`, `labs/ch14b/diagnose-env.sh`, `labs/ref/professional-config.sh`

## HOOK

**[ON SCREEN]** "Half of the commits a contractor pushed to the company repository carry her private email address. She says she set the work address months ago. Who is right?"

Your CTO asks: "Half of the commits a contractor pushed to the company repository carry her private email address. She says she set the work address months ago. Who is right?"

Both. She did set the work address, in a separate file, with a rule that says: use this file for repositories under `~/work`.

**[PAUSE]**

The rule has no trailing slash. So it never matched, and Git said nothing. Configuration fails silently: a rule that does not apply produces no warning, only commits with the wrong address. This video is about configuration that depends on where you are, about settings you should choose on purpose, and about the tools that make Git say what it is doing.

## INTRODUCTION

In the last video you learned where settings come from and which value wins. Now we use that.

Four topics. Include files and conditional includes: two identities on one machine, and the ways the rule silently does not apply. The settings to decide deliberately: each one has a cost, and "I never set it" is also a decision, made by the default. Aliases: what they expand to, and their traps. And environment variables for diagnosis. At the end I show the course's reference configuration, in which every line has a stated reason.

## LEARNING OBJECTIVES

After this video you can:

1. Configure two identities with `includeIf`, and prove which one a repository uses.
2. Give the reasons why a conditional include does not take effect.
3. Justify a pull, push, fetch, merge, rebase, diff and rerere setting by its downside.
4. Write an alias, including a shell alias with arguments, and trace what it runs.
5. Trace a Git command with environment variables.

## CONCEPT

**Includes.** In one sentence: `include.path` reads another file at the point where the line stands, and `includeIf.<condition>.path` does so only when a condition about the current repository is true.

The conditions in Git 2.55 are `gitdir:` and `gitdir/i:`, where the location of the repository's `.git` directory matches a glob; `onbranch:`, the branch that is checked out; and `hasconfig:remote.*.url:`, where some remote of the repository has a matching URL. In a `gitdir` pattern, a leading `~/` is your home directory, and a trailing slash means "everything below".

**Five ways the rule silently does not apply.** The curriculum's objective and the interview question count four; the textbook lists five, and I give you all five. Each one produces commits with the wrong address and no message.

One, the trailing slash: `gitdir:~/work` matches only a repository whose `.git` directory is `~/work` itself.

Two, order: the include is read where it stands. If the `[user]` section comes after it in the including file, the general value is read last and wins. Keep conditional includes at the end of the file.

Three, not in a repository: `gitdir` needs a `.git` directory. In `~/work` itself there is none.

Four, a missing file: an include that names a file that does not exist is skipped without an error.

Five, asking the wrong question: a scope option such as `--global` switches include processing off, so the usual diagnostic lies unless you add `--includes`.

**A team file, opted into.** Git never reads configuration from the files it tracks. If it did, cloning a repository would let its author set your pager, your SSH command and your hooks. A team that wants shared settings commits a file and asks each member to include it once. Review changes to such a file like code: it can define an alias that runs a shell command.

**The settings to decide deliberately.** The textbook lists twenty settings in a table with six columns: what it does, why it matters, its downside, whether it is optional, and whether it is personal or a team matter. Read the downside column aloud for the seven kinds this video's objective names.

**[ON SCREEN]** Rows of the table of section 14B.5, one at a time, with the "Downside" column highlighted.

`pull.rebase`: how `git pull` integrates. With nothing set, a diverged pull is fatal. Downside of `true`: it gives unpublished commits new IDs and flattens local merges. `pull.ff=only`: pull refuses anything but a fast-forward; in configuration it wins over `pull.rebase`, so a diverged pull needs a flag.

`push.autoSetupRemote`, which the textbook dates to Git 2.37: the first push of a branch sets its upstream. Downside: a mistyped branch name is published at once. `push.default`: leave the default, `simple`.

`fetch.prune`: fetch deletes remote-tracking branches whose branch is gone. Downside: that ref may have been your last name for those commits.

`merge.conflictStyle`, with `zdiff3` since Git 2.35: adds the common ancestor to a conflict. Downside: longer conflict regions, and a third marker.

`rebase.autoSquash`: downside, a title that starts with `fixup!` by accident is moved. `rebase.autoStash`: the final apply can conflict. `rebase.updateRefs`, Git 2.38: it moves branches you did not name.

`diff.algorithm`: `myers` is the default; `histogram` reads better when code moves. Downside: your diff differs from a colleague's. The setting changes what you see, never what is stored.

`rerere.enabled`: records conflict resolutions and replays them. Downside: a wrong resolution is replayed too.

And one more with a sharp edge: `help.autocorrect`. `immediate` runs a guess; since Git 2.49 the value `1` means `immediate`.

The textbook's rule for teams: split the few settings a team must agree on, such as the default branch name, line-ending attributes, and whether signatures are required, from everything else, which stays personal. And put a comment on each line.

**Aliases.** In one sentence: an alias is a configuration value under `alias.<name>` that Git substitutes for the name when it is the first word of a command line, appending any further arguments.

If the value starts with `!`, it is handed to the shell and run from the top-level directory of the repository. Otherwise it is a Git command line. An alias cannot replace an existing command. Defining one is `git config set`, which is 🟡 CAUTION.

Two traps, both about arguments. Arguments after the alias name are appended to the expansion. And for a shell alias, Git runs `sh -c` with the alias and `"$@"`: the arguments are available as `$1`, and are also appended. The manual's remedy is a function that consumes them.

Never use aliases in scripts, hooks or CI: they exist in your configuration only.

The textbook carries one caveat here that I repeat: the manual documents a subsection form for alias names with unusual characters, and which release introduced that form was not checked.

**Environment variables for diagnosis.** Configuration says what Git should do. These variables make Git say what it is doing.

**[ON SCREEN]** The table of section 14B.7.

`GIT_TRACE=1`: alias expansion, and the built-in and external commands that are started. `GIT_TRACE_SETUP=1`: the `.git` directory, the working tree, the current directory and prefix Git settled on; use it when Git picks up the wrong repository, or none. `GIT_TRACE_PACKET=1`: the protocol conversation with a remote. `GIT_TRACE_CURL=1`: the HTTP exchange. `GIT_SSH_COMMAND`: replaces the `ssh` program and its options for this command. `GIT_TRACE2_PERF=1`: timings inside a command. A value of `1`, `2` or `true` writes to standard error; an absolute path appends to that file.

The HTTP variables need a server, so they are not run here. The textbook's version note: older tutorials name `GIT_CURL_VERBOSE`; the Git 2.55 manual documents `GIT_TRACE_CURL`; since which release is not established. Keep `GIT_TRACE_REDACT` at its default, so that `Authorization` headers stay out of the output you paste into a ticket.

## MENTAL MODEL

For includes, the textbook's analogy: a footnote that says "insert appendix D here, but only in the edition for the Bengaluru office". The analogy breaks because order matters: text inserted early is overridden by a later line of the including file.

For aliases: a speed-dial key. It breaks at the arguments: whatever you type after the alias is added to the end of the expansion.

And one frame for the whole video: configuration is silent. A rule that does not match, a key that is misspelled, an alias that expands to something else: none of them prints a warning. So the skill is not writing configuration. It is asking Git what it read, with `--show-origin`, and what it ran, with `GIT_TRACE`.

## DIAGRAM

**[DIAGRAM]** The diagram of section 14B.4.

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

On the left, the personal file: a `[user]` section first, and the conditional include last. On the right, the work file with one line. The arrow is the include: the work file is read at that point, and only if the condition holds. Under the boxes, the two reading orders. Inside `~/work`, two values are read, and the later one wins. Elsewhere, one value.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/ch14b/includes.sh`.

```bash
labs/run ch14b/includes
```

In this demo the identity comes from configuration. The lab library normally pins it through environment variables, which would hide the effect.

<!-- snippet: ch14b/includes/01-before -->
```text
$ git -C ~/work/inference-gateway config get --show-origin user.email
file:$LAB/ch14b/includes/home/.gitconfig	you@example.com
$ git -C ~/oss/evalkit config get --show-origin user.email
file:$LAB/ch14b/includes/home/.gitconfig	you@example.com
```
<!-- /snippet -->

Before: both repositories use the same address.

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

A second file with the work address, and one `git config set --global` 🟡 CAUTION for the conditional include. Predict what `git config get --all --show-origin user.email` prints inside the work repository.

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

Two global values, and the second, from the included file, wins. In `~/oss/evalkit`, the file is not read.

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

The commits prove it: the new commit carries the work address.

Now the failures. For each one, predict the address before the output.

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

No trailing slash: the personal address. This is the contractor.

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

The same two sections in the other order: the general value is read last, and wins.

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

In `~/work` itself, which is not a repository, the rule does not apply; in a new repository below it, it does.

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

A missing file is skipped without an error.

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

And the diagnostic that lies: `git config get --global user.email` prints the personal address, because naming a scope switches include processing off. Add `--includes`.

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

By remote, not by directory: the identity changes the moment the remote is added.

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

A team file, opted into with one `include.path` in `.git/config`. A relative path is resolved against the file that contains it.

**[TERMINAL]** Caption bar: `labs/ch14b/settings.sh`.

```bash
labs/run ch14b/settings
```

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

`git var GIT_DEFAULT_BRANCH`: `main` with the lab's global file, `master` with none.

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

`help.autocorrect`: `immediate` ran the guess. With a typo that resolves to a destructive command, it would have run that.

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

A function was moved to the top of a file and edited. Both diffs are correct. `histogram` reports one block added and one removed, which is what happened.

**[TERMINAL]** Caption bar: `labs/ch14b/aliases.sh`.

```bash
labs/run ch14b/aliases
```

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

Five aliases that earn their place.

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

`st` is `status -sb`. `lg` draws every ref as a graph: the fourth command of the diagnosis ritual, in two letters. `last` shows the newest commit with the files it touched.

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

`unstage` is `restore --staged --`, 🟡 CAUTION as you know from V017. The trailing `--` makes everything after it a path.

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

`amend` 🟡 CAUTION is `commit --amend --no-edit`. Everything V021 said about amending published commits applies.

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

`GIT_TRACE=1` prints the expansion, and then the built-in command that runs.

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

Arguments are appended. Convenient for `lg -2`; a trap for an alias that hard-codes `HEAD`.

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

A shell alias runs in the top-level directory, although you were in `gateway/`. `GIT_PREFIX` holds the directory you came from.

Predict what `git tracked HEAD` does when the alias uses `$1` in the middle of a pipeline.

**[PAUSE]**

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

The argument is available as `$1`, and is also appended, here to `head`. The trace shows the command line Git started. The function form consumes the arguments.

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

`alias.status` is ignored: built-in commands win.

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

**[TERMINAL]** Caption bar: `labs/ch14b/diagnose-env.sh`.

```bash
labs/run ch14b/diagnose-env
```

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

<!-- snippet: ch14b/diagnose-env/03-trace-to-file -->
```text
$ GIT_TRACE=$HOME/git-trace.log git st
## main
$ sed -e 's/^[^ ]* [^ ]* *//' ~/git-trace.log | grep -E 'alias|built-in'
trace: alias expansion: st => status -sb
trace: built-in: git status -sb
```
<!-- /snippet -->

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

`GIT_SSH_COMMAND`, shown without a network: a stand-in script named `ssh` prints its arguments and exits. No connection is made. Git appended its own arguments to yours.

**[TERMINAL]** Caption bar: `labs/ref/professional-config.sh`.

```bash
labs/run ref/professional-config
```

<!-- snippet: ref/professional-config/01-the-file -->
```text
$ cat ~/.gitconfig
# ~/.gitconfig: personal Git configuration, checked on Git 2.55.0.
# Explained line by line in reference/professional-git-configuration.md.
[user]
	name = Lab User
	email = you@example.com
	useConfigOnly = true # refuse to guess an identity
[init]
	defaultBranch = main # unconfigured Git 2.55 still creates master
[core]
	excludesFile = ~/.config/git/ignore # personal ignore patterns
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
	missingCommitsCheck = error # a deleted todo line stops the rebase
[rerere]
	enabled = true # remember conflict resolutions
[maintenance "rerere-gc"]
	auto = 0 # avoid the MERGE_RR.lock race of Git 2.55
[diff]
	algorithm = histogram # moved code reads as a move
	colorMoved = default
[tag]
	sort = version:refname # v1.10.0 after v1.9.0
[help]
	autocorrect = prompt # show the suggestion, run nothing
[safe]
	bareRepository = explicit # the planned Git 3.0 default
[transfer]
	credentialsInUrl = die # refuse a token inside a remote URL
[alias]
	st = status -sb
	lg = log --graph --decorate --oneline --all
	last = log -1 --stat
	unstage = restore --staged --
	amend = commit --amend --no-edit
	pushf = push --force-with-lease --force-if-includes
[includeIf "gitdir:~/work/"]
	path = ~/.gitconfig-work # last, so that it wins inside ~/work/
```
<!-- /snippet -->

The course's reference configuration. Read the comments: every line has a reason. Notice where the conditional include stands: last. And notice the alias `pushf`: the textbook calls it the alias most worth having, because the safe form of a forced push is long enough that people type `--force` instead. Part 2 explains that command; do not use it before then.

## COMMON MISTAKES

1. **An `includeIf` rule that never matches.** Root cause: the `gitdir` pattern has no trailing slash, so it matches only a `.git` directory at exactly that path.
2. **The rule matches and the wrong value still wins.** Root cause: the `[user]` section stands after the include in the file, and the value read last wins.
3. **`git config get --global user.email` shows the "wrong" address.** Root cause: naming a scope switches include processing off; add `--includes`, or ask without a scope inside the repository.
4. **A shell alias receives its argument twice.** Root cause: Git runs the alias with `"$@"` appended; wrap the body in a function that consumes the arguments.
5. **A build script uses an alias and fails on CI.** Root cause: aliases exist in your configuration only.

## PRODUCTION EXAMPLE

The contractor, as the textbook resolves it. She did set her work address, in `~/.gitconfig-work`, with an `includeIf` on `gitdir:~/work`. The pattern has no trailing slash, so it never matched. Diagnose with `git config get --all --show-origin user.email` inside the repository. Fix the pattern. Then set `user.useConfigOnly=true` and remove the global default address, so that a repository outside both directories refuses to commit. And published commits keep the address they have.

A second one from the textbook: a platform team runs a script of `git config set --global` lines on every laptop. Six months later nobody remembers why `pull.rebase` is `true`. A comment on each line, and a split between team settings and personal ones, prevent that. And the first reply to "Git does something strange on the build machine" is two commands run there: `git config list --show-scope --show-origin`, and the failing command with `GIT_TRACE=1`.

## PRACTICE EXERCISE

Do Lab 5.2, "Two identities with `includeIf`", in [`lab-manual/m05-configuration.md`](../../lab-manual/m05-configuration.md). Its first step points the global configuration at a per-lab file; do not skip it.

Before each `git config get --show-origin user.email`, predict the address and the file it comes from. In the failure scenario, predict which of the five causes you are about to create.

## INTERVIEW QUESTION

Q57: "Your `includeIf` rule for `~/work/` exists, yet a work repository commits with your personal address. Give four causes and the command that distinguishes them."

Answer aloud. A strong answer names causes that are different in kind: about the pattern, about position in the file, about the file that is included, about where the repository is, about how you asked. For each, say what the distinguishing command would print. You know five; give the four you can explain best.

## RECAP

You should now be able to say: `includeIf` reads another file when a condition about the repository holds, and I keep it last in my global file so that it wins. It fails silently when the `gitdir` pattern lacks its trailing slash, when a later line overrides it, outside a repository, when the file is missing, and when I ask with a scope option and no `--includes`. Every setting I choose has a downside that I can name. An alias is substituted by Git and gets my arguments appended; a shell alias runs from the top of the repository. And `GIT_TRACE=1` shows what Git ran, while `GIT_TRACE_SETUP=1` shows which repository it found.

## HOMEWORK

- Read sections 14B.4 to 14B.7 of [Chapter 14B](../../textbook/ch14b-config-tags-signing.md).
- Do Lab 5.3, "Aliases", in [`lab-manual/m05-configuration.md`](../../lab-manual/m05-configuration.md), then fill in the worksheet of Lab 5.4, "Your deliberate configuration (a worksheet)", and keep it; V174 revisits it.
- Challenge: Exercise 5.9, Level 4, "two work repositories, two wrong addresses", in [`exercises/m01-m05-foundations.md`](../../exercises/m01-m05-foundations.md).
