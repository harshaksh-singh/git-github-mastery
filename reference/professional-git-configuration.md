# A professional Git configuration

> **Baseline.** Git 2.55.0 on macOS. The file below is `labs/ref/professional.gitconfig`. It was loaded in a sandbox, accepted by `git config list`, and every alias in it was run; the transcripts are real output from `labs/ref/professional-config.sh`. The settings and their trade-offs are those of Chapter 14B, section 14B.5; nothing here is new.

## 1. What this file is, and what it is not

A configuration file is a list of decisions. Chapter 14B, section 14B.5 names the twenty settings that change what everyday commands do, and says that "I never set it" is also a decision, made by the default. This page gives one defensible set of answers, with the reason, the downside, and who should decide, for every line.

Three rules before you copy anything:

1. **Do not copy it whole.** Read each line, and take the lines whose downside you accept. The identity lines are placeholders: put your own name and address there.
2. **Personal settings and team conventions are different things.** A global file configures one person on one machine. What a team must agree on (the default branch name, line-ending attributes, whether signatures are required) belongs in the repository (`.gitattributes`) and on the server (rulesets), not in everyone's `~/.gitconfig` (14B.5, "In production").
3. **Keep the file under version control, with a comment on each line.** `git config set` rewrites a file that keeps no history (🟡, 14B.3), and six months later nobody remembers why a value is what it is.

> **Version note.** Older behavior: `git config --global <key> <value>`, `git config --list`. Current behavior: `git config set`, `git config get`, `git config list`; the old forms still work. Since: Git 2.46. Recommended: the subcommands, with a version check in scripts that run elsewhere, for example on the Git 2.43.0 of Ubuntu 24.04.

## 2. The file

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

The lab's own global file also has a `[gc]` section that switches reflog expiry off (Chapter 1, section 1.7). It belongs to the lab and is not part of this file: do not copy it.

## 3. Git accepts it

`git config list --file <file>` parses a file without making it your configuration. An exit status of 0 means every line is well-formed. That is not the same as every key being right: Git stores a mistyped key without complaint and then ignores it (Chapter 14B, section 14B.3). The second half of the transcript therefore compares each key with the names that `git help --config` documents.

<!-- snippet: ref/professional-config/02-accepted -->
```text
# Git parses the file and lists every key. A syntax error would stop here with "bad config line".
$ git config list --file ~/.gitconfig > /dev/null
[exit status: 0]
$ git config list --file ~/.gitconfig --name-only | grep -c .
27
# Every key is a name that Git 2.55.0 documents. A mistyped key is accepted silently by the
# parser, so compare the names with "git help --config". Alias names and include conditions
# carry a part that you choose; they are counted separately.
$ git config list --file ~/.gitconfig --name-only | grep -v -e "^alias\." -e "^includeif\." | while read -r key; do git help --config | grep -q -i -x "$key" || echo "not documented: $key"; done
$ git config list --file ~/.gitconfig --name-only | grep -c -e "^alias\." -e "^includeif\."
7
```
<!-- /snippet -->

The loop printed nothing: all twenty documented keys exist in Git 2.55.0. The seven remaining names are the six aliases and the conditional include, whose names contain a part that you choose.

## 4. Every line explained

The columns are those of the settings table in section 14B.5. "Optional?" says how strongly the textbook recommends the line; "Personal or team" says who decides.

| Line | What it does | Why it matters | Downside | Optional? | Personal or team | Section |
|---|---|---|---|---|---|---|
| `user.name`, `user.email` | Identity copied into every commit and annotated tag | Attribution; GitHub links commits to accounts by this email | Unchecked text; the wrong scope gives the wrong identity for years | Required | Personal, one per context | 14B.5, 6.5 |
| `user.useConfigOnly = true` | Git refuses to guess an identity from the user and host name | A commit without a configured identity fails, in place of carrying a made-up address | A new machine cannot commit until you configure it | Recommended | Personal | 14B.5, 6.13 |
| `init.defaultBranch = main` | Name of the first branch in `git init` | Unconfigured Git 2.55 creates `master`; Git 3.0 will create `main` | None found; new repositories only | Recommended | Personal, following the team's name | 14B.5 |
| `core.excludesFile = ~/.config/git/ignore` | Your personal ignore file (this path is also the default when `XDG_CONFIG_HOME` is not set) | Editor and operating-system files stay out of project `.gitignore` files | A colleague without it commits what you ignore | Optional | Personal | 14B.5, 4.5 |
| `pull.ff = only` | `git pull` refuses anything but a fast-forward | You integrate deliberately; no merge commit by accident | In configuration `only` wins over `pull.rebase`, so a diverged pull needs a flag: `--rebase` or `--no-rebase` | Decide `pull.ff` or `pull.rebase` one way | Personal; a team convention keeps history uniform | 14B.5, 12.6 |
| `push.autoSetupRemote = true` | The first push of a branch sets its upstream (Git 2.37 or later) | No "has no upstream branch" stop | A mistyped branch name is published at once | Optional | Personal | 14B.5, 12.5 |
| `fetch.prune = true` | Fetch deletes remote-tracking branches whose branch is gone on the server | `git branch -r` stays true | That ref, and its reflog, may have been your last name for those commits | Optional | Personal | 14B.5, 12.11 |
| `merge.conflictStyle = zdiff3` | Adds the common ancestor to every conflict (Git 2.35 or later) | You see what both sides changed from | Longer conflict regions; a third marker | Recommended | Personal | 14B.5, 8.9 |
| `rebase.autoSquash = true` | Places `fixup!`, `squash!` and `amend!` commits in an interactive rebase | Makes fixup commits routine | A title that starts with those words by accident is moved; it applies to interactive rebases only | Optional | Personal | 14B.5, 9.7 |
| `rebase.updateRefs = true` | Branches pointing into the rebased range move with it (Git 2.38 or later) | Stacked branches stay stacked | Moves branches you did not name | Optional | Personal | 14B.5, 9.9 |
| `rebase.missingCommitsCheck = error` | A line deleted from the todo list stops the rebase; the default `ignore` drops the commit silently | A commit cannot vanish from an interactive rebase by a slip of the editor | You must write `drop` to remove a commit on purpose | Optional | Personal | 9.19, 9.21 |
| `rerere.enabled = true` | Records conflict resolutions and replays them | Repeated rebases of a long branch | A wrong resolution is replayed too; leave `rerere.autoUpdate` off | Optional | Personal | 14B.5, 14C.3 |
| `maintenance.rerere-gc.auto = 0` | Switches off the automatic `rerere-gc` maintenance task | On Git 2.55, with rerere enabled, that background task can make a rebase die with `Unable to create ... MERGE_RR.lock` | Old recorded resolutions are no longer expired automatically; run `git rerere gc` occasionally | Needed with the line above | Personal | 14C.3 |
| `diff.algorithm = histogram` | Diff algorithm; the default is `myers` | Moved code reads as a move | Your diff differs from a colleague's; it changes what you see, never what is stored | Optional | Personal | 14B.5, 14A.6 |
| `diff.colorMoved = default` | Colors moved lines differently | Review of refactorings | Terminal only | Optional | Personal | 14B.5 |
| `tag.sort = version:refname` | `git tag` lists `v1.10.0` after `v1.9.0` | Tag lists read as version lists | None found; add `versionsort.suffix` if you use pre-release suffixes | Optional | Personal | 14B.9 |
| `help.autocorrect = prompt` | A mistyped command: Git shows its guess and asks | Saves retyping without running a guess | None. Avoid `immediate`, which runs the guess; since Git 2.49 the value `1` means `immediate` | Optional | Personal | 14B.5 |
| `safe.bareRepository = explicit` | Git uses a bare repository only when you name it with `--git-dir` or `GIT_DIR` | A bare repository hidden inside a working tree is not picked up by walking up directories; the planned Git 3.0 default | Commands run inside bare repositories need `--git-dir`; fix server and backup scripts first | Recommended | Personal | 14D.4, 21B.3 |
| `transfer.credentialsInUrl = die` | Git refuses a remote URL that contains a password or token; the default is `allow` | A token in a URL is published to logs, history and backups | With `die`, `git remote set-url` also refuses to replace a bad URL; repair it with `git config set remote.origin.url <clean URL>`, and revoke the token | Recommended | Personal | 16.7 |
| `alias.*` | Six aliases, section 6 below | Typing; `pushf` makes the guarded forced push shorter than `--force` | They exist in your configuration only: never use them in scripts, hooks or CI | Optional | Personal | 14B.6 |
| `includeIf "gitdir:~/work/"` | Reads `~/.gitconfig-work` only for repositories under `~/work/` | Two identities without per-repository settings | The pattern needs the trailing slash; the include must stand last, or a later `[user]` wins | Optional | Personal | 14B.4 |

Settings from section 14B.5 that this file leaves at their default, on purpose:

| Setting | Why it is not in the file |
|---|---|
| `pull.rebase` | `pull.ff = only` already answers the question; choose `pull.rebase = true` instead if you prefer pulls to rebase, and know that it gives unpublished commits new IDs and flattens local merges |
| `push.default` | Leave the default, `simple` (since Git 2.0); `matching` and `upstream` can update a branch you did not mean |
| `rebase.autoStash` | Optional; the final apply can conflict |
| `core.editor` | Personal; a graphical editor needs its wait option, such as `code --wait`. Test it before relying on it |
| `core.autocrlf` | Leave it unset on macOS; it normalizes for you only. The repository-wide tool is `.gitattributes` (Chapter 14C, section 14C.5) |
| `commit.gpgSign` | In the signing block of section 7: with it, every commit fails when the key is unavailable |
| `credential.helper` | Chapter 16, section 16.5: which helper answers, and where the token lives |

## 5. Two identities

The last two lines of the file include a second file for everything under `~/work/`. That file holds one line that matters:

```text
[user]
	email = lab.user@corp.example
```

The transcript asks the same question in two repositories; `--show-origin` names the file that answered.

<!-- snippet: ref/professional-config/03-identities -->
```text
$ cd ~/oss/retrieval-api
$ git config get --show-origin user.email
file:$LAB/ref/professional-config/home/.gitconfig	you@example.com
$ cd ~/work/retrieval-api
$ git config get --show-origin user.email
file:$LAB/ref/professional-config/home/.gitconfig-work	lab.user@corp.example
$ git var GIT_DEFAULT_BRANCH
main
$ git config get --show-origin --show-scope merge.conflictStyle
global	file:$LAB/ref/professional-config/home/.gitconfig	zdiff3
```
<!-- /snippet -->

```text
Observed behavior : commits under ~/work/ carry the personal address although ~/.gitconfig-work sets another.
Git state         : git config get --all --show-origin user.email lists one value, or two in the wrong order.
Mechanism         : gitdir: patterns match the path of the .git directory; without a trailing slash the
                    pattern names one path, not everything below it. An include is read where it stands.
Root cause        : the pattern lacks the trailing slash, or [user] comes after the include and wins.
Why Git does this : configuration is read top to bottom and the last value wins, in every scope.
Correct fix       : "gitdir:~/work/" with the slash, as the last section of the file.
Prevention        : user.useConfigOnly=true and no global default address, so that a miss is an error.
```

The box is the diagnosis of Chapter 14B, section 14B.4 ("In production"), where it is shown in a transcript.

## 6. The aliases, each one run

An alias is a configuration value under `alias.<name>` that Git substitutes for `<name>` when it is the first word of a command line, appending any further arguments (14B.6).

| Alias | Expands to | Risk of the expansion | Why it earns its place |
|---|---|---|---|
| `st` | `status -sb` | 🟢 | The short format plus the branch line |
| `lg` | `log --graph --decorate --oneline --all` | 🟢 | Every ref as a graph, one line per commit: the fourth command of Chapter 1's diagnosis ritual |
| `last` | `log -1 --stat` | 🟢 | The newest commit with the files it touched; no hard-coded `HEAD`, so that `git last <branch>` works |
| `unstage` | `restore --staged --` | 🟡 | The trailing `--` makes everything after it a path |
| `amend` | `commit --amend --no-edit` | 🟡 | Replaces the tip commit with one that includes whatever is staged; unpublished commits only |
| `pushf` | `push --force-with-lease --force-if-includes` | 🔴 | The guarded form is long enough that people type `--force` instead; a forced push remains a forced push |

The repository for the runs is a small retrieval service with three commits on `main`, already pushed, and one branch.

<!-- snippet: ref/professional-config/04-st-lg-last -->
```text
$ git st
## main...origin/main
$ git lg
* 1f7e0f4 (feature/rerank) Add reranker
* 9e4300f (HEAD -> main, origin/main) Add search defaults
* 88016e2 Add search endpoint
* 7e22013 Add README
$ git last
commit 9e4300f279b95a038a64b05b66211e4b66239ce5
Author: Lab User <lab.user@corp.example>
Date:   Mon Sep 7 10:26:00 2026 +0530

    Add search defaults

 config/search.yaml | 1 +
 1 file changed, 1 insertion(+)
$ git last feature/rerank
commit 1f7e0f4077121a38ac427f0e51898099f3ce4ec4
Author: Lab User <lab.user@corp.example>
Date:   Mon Sep 7 10:29:00 2026 +0530

    Add reranker

 api/rerank.py | 2 ++
 1 file changed, 2 insertions(+)
```
<!-- /snippet -->

`git st` prints one line: the branch and its upstream, with nothing to report. `git last feature/rerank` shows the last commit of the branch you name, because arguments are appended to the expansion. The author address is the work address: the repository lives under `~/work/`.

<!-- snippet: ref/professional-config/05-unstage-amend -->
```text
$ printf 'timeout_ms: 800\n' >> config/search.yaml
$ printf 'scratch\n' > notes.txt
$ git add .
$ git st
## main...origin/main
M  config/search.yaml
A  notes.txt
$ git unstage notes.txt
$ git st
## main...origin/main
M  config/search.yaml
?? notes.txt
$ git amend
[main b84c566] Add search defaults
 Date: Mon Sep 7 10:26:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 config/search.yaml
$ git st
## main...origin/main [ahead 1, behind 1]
?? notes.txt
```
<!-- /snippet -->

`git unstage notes.txt` returned the new file to untracked (`??`) and left the staged change to `config/search.yaml` alone. `git amend` then replaced the tip commit with one that includes that staged change. The last `git st` reads `[ahead 1, behind 1]`: the amended commit is a new commit with a new ID, and the server still has the old one. The old commit is one reflog entry away (`git reset --soft 'HEAD@{1}'`).

<!-- snippet: ref/professional-config/06-pushf -->
```text
# The amended commit replaced one that the server already has, so a plain push is rejected.
$ git push
To $LAB/ref/professional-config/home/server/retrieval-api.git
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to '$LAB/ref/professional-config/home/server/retrieval-api.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git pushf --dry-run
To $LAB/ref/professional-config/home/server/retrieval-api.git
 + 9e4300f...b84c566 main -> main (forced update)
$ git pushf
To $LAB/ref/professional-config/home/server/retrieval-api.git
 + 9e4300f...b84c566 main -> main (forced update)
$ git st
## main...origin/main
?? notes.txt
```
<!-- /snippet -->

The plain push is rejected as a non-fast-forward, which is Git protecting the server's commit. `git pushf --dry-run` previews the forced update: the ID to the left of the three dots is the server's current value, the one that will leave the branch. The real `git pushf` succeeds because the server's branch still is what this clone last integrated. On a branch that other people push to, this is the moment to stop and talk to them, not to reach for the alias (Chapter 12, section 12.8).

> **Root cause.** `safe.bareRepository = explicit` did not stop the push to the bare repository `server/retrieval-api.git`: a push or a clone names the repository, which is what "explicit" asks for. The setting refuses only a bare repository that Git would find by itself while walking up from the current directory (Chapter 14D, section 14D.4).

## 7. The signing block

Signing settings are kept in a file of their own, because `commit.gpgSign = true` makes every commit fail on a machine where the key is missing (14B.5). Add the block once the key exists, with an `[include]` line (`path = ~/.gitconfig-signing`) placed before the conditional include.

<!-- snippet: ref/professional-config/07-signing-block -->
```text
$ cat ~/.gitconfig-signing
# ~/.gitconfig-signing: SSH signing. Add it with an [include] line once the key exists.
[gpg]
	format = ssh # sign with an SSH key (Git 2.34 or later)
[user]
	signingKey = ~/.ssh/id_ed25519_signing.pub
[gpg "ssh"]
	allowedSignersFile = ~/.config/git/allowed_signers # needed to verify
[commit]
	gpgSign = true # every commit; --no-gpg-sign opts one out
[tag]
	gpgSign = true # every annotated tag becomes a signed tag
$ git config list --file ~/.gitconfig-signing
gpg.format=ssh
user.signingkey=~/.ssh/id_ed25519_signing.pub
gpg.ssh.allowedsignersfile=~/.config/git/allowed_signers
commit.gpgsign=true
tag.gpgsign=true
[exit status: 0]
```
<!-- /snippet -->

| Line | What it does | Why it matters | Downside | Optional? | Personal or team | Section |
|---|---|---|---|---|---|---|
| `gpg.format = ssh` | Signatures are made by `ssh-keygen`; the default format is `openpgp` | One key type for authentication and signing (SSH signing needs Git 2.34 or later) | The option names keep "gpg" for all three formats, which confuses readers | Optional | Personal | 14B.15 |
| `user.signingKey` | The key file to sign with | Without it Git falls back to `gpg.ssh.defaultKeyCommand` | A path that does not exist gives `error: gpg failed to sign the data` | Needed for signing | Personal | 14B.16 |
| `gpg.ssh.allowedSignersFile` | The file that maps identities to public keys, used to verify | Without it a signed commit shows `No signature` and verification fails | You maintain the file; a key rotation adds a line, it never replaces one | Needed to verify | Personal file, team content | 14B.16 |
| `commit.gpgSign = true` | Signs every commit; `--no-gpg-sign` opts one out | Evidence that a key holder made the commit | Every commit fails when the key is unavailable | Optional, unless a rule requires signatures | Personal setting, team policy | 14B.5, 14B.16 |
| `tag.gpgSign = true` | Every annotated tag becomes a signed tag | Release tags carry a signature without `-s` | As above, for tags | Optional | Personal setting, team policy | 14B.16 |

This transcript only parses the block. The end-to-end run (create the key, sign, write the allowed-signers file, verify with `git verify-commit` and `git log --format='%G?'`) is Chapter 14B, section 14B.16, and Lab 24.1. What a signature proves, and what it does not, is section 14B.17.

> **Unverified.** The minimum OpenSSH version for SSH signing was not established (Chapter 14B, section 14B.22). The Git manual states only that `valid-after` and `valid-before` in the allowed-signers file need OpenSSH 8.8.

## 8. What belongs to the team, and where it goes

| Decision | Where it lives | Why not in `~/.gitconfig` | Section |
|---|---|---|---|
| Line endings and binary files | `.gitattributes`, committed | `core.autocrlf` is per user; attributes travel with the repository | 14C.5 |
| Diff, merge and filter drivers | The attribute in `.gitattributes`; the driver definition in each clone, by a setup script | Attributes travel, drivers do not | 14C.4, 14C.8 |
| Hooks | A directory in the repository plus `core.hooksPath`, set by a setup step | Hooks are not cloned and can be skipped; they cannot enforce policy | 14C.11, 14C.13 |
| Required reviews, checks, signatures, no force push | Rulesets on the server (GitHub, not Git) | A local setting binds one clone | Chapter 18 |
| Lines to ignore in blame | `.git-blame-ignore-revs`, committed, with `git config set blame.ignoreRevsFile ':(optional).git-blame-ignore-revs'` per clone | The key is per clone; without the `:(optional)` prefix every blame fails in a commit that lacks the file | 14A.17 |
| Submodule safety, where submodules are used | `submodule.recurse=true` and `push.recurseSubmodules=check`, per clone | They matter only in such repositories | 23.7, 23.8 |

## 9. Install and check

```bash
cp labs/ref/professional.gitconfig ~/.gitconfig.new      # edit name and email first
git config list --file ~/.gitconfig.new                  # must exit 0
git config list --show-origin --show-scope --global      # what you have today
```

Replace your global file only after you have compared the two listings, and keep the old file. In the labs, never write your real global configuration: `labs/shell` isolates it, and a lab that changes global settings points `GIT_CONFIG_GLOBAL` at a file inside the sandbox first (Lab 5.4 builds a file like this one, one decision at a time).

## 10. Sources

- Chapter 14B: [Configuration, Aliases, Tags and Signing](../textbook/ch14b-config-tags-signing.md), sections 14B.2 to 14B.6 and 14B.15 to 14B.17.
- [git-config](https://git-scm.com/docs/git-config): every key; on your machine `git help config` and `git help --config`.
- Chapter 9, section 9.19 (rebase configuration); Chapter 14C, section 14C.3 (rerere and the maintenance lock); Chapter 14D, section 14D.4 (`safe.bareRepository`); Chapter 16, section 16.7 (`transfer.credentialsInUrl`).
- Consolidated list: [references](references.md).
