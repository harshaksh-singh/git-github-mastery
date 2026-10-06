# Git command reference

> **Baseline.** Git 2.55.0 on macOS. Every command and option below is taught in Chapters 1 to 14D or 22 to 26 and was run in this book's labs, unless the entry says "not run here" (Git 2.56 additions). Nothing here is new: this file is an index into the textbook.

## 1. How to use this reference

Commands are grouped by what you are trying to do: daily use, history, branches and integration, remotes, undo, recovery, debugging, advanced, plumbing. Each entry has the same six parts.

| Part | What it tells you |
|---|---|
| Heading | The command, its risk label, and the textbook section that teaches it (the number before the dot is the chapter) |
| Purpose | What the command does to the repository, in one sentence |
| Forms | The forms the textbook teaches, not the whole manual; `git help <command>` has the rest |
| Example | One command line taken from the chapter's usage |
| Mistake | The common mistake, from the chapter's "What can go wrong" table |
| Recover | What to run when it went wrong |

Risk labels are those of Chapter 1, section 1.8: 🟢 SAFE reads state or only adds objects; 🟡 CAUTION moves refs or rewrites local history and is recoverable through the reflog; 🔴 DANGEROUS can destroy uncommitted work, remote history, or the safety net itself. A heading with two labels means that the forms differ; the entry says which form carries which label. Where chapters disagree about a label, this file uses the stricter one ([command safety](command-safety.md), section 12). The five answers for every 🟡 and 🔴 form (what it changes, what it can destroy, preview, recovery, when appropriate) are in [command safety](command-safety.md) and are not repeated here.

Placeholders: `<path>`, `<commit>`, `<branch>`, `<id>` (an object ID), `<remote>`, `<upstream>`. Section numbers map to chapter files as listed in [command safety](command-safety.md), section 13. For the same commands as one-line tables, see the [Git cheat sheet](../cheatsheets/git-cheat-sheet.md).

> **Version note.** Older behavior: `git config --get`, `git checkout <branch>`, `git checkout -- <path>`, `git stash save`. Current behavior: `git config get|set|list|unset`, `git switch`, `git restore`, `git stash push`; the old forms still work. Since: `git switch` and `git restore` Git 2.23 (no longer labelled experimental from 2.51), the `git config` subcommands Git 2.46, `git stash push` Git 2.13. Recommended: write the new forms, read the old ones; the `git config` subcommands fail on older Gits such as the 2.43.0 that Ubuntu 24.04 ships (Chapter 1, section 1.16).

## 2. Daily use

### `git init` 🟢 · 1.9, 14D.5

- **Purpose.** Creates `.git`; in an existing repository it only adds missing template files.
- **Forms.** `git init`, `git init <directory>`, `git init -b <branch>`, `git init --bare <directory>`, `git init --object-format=sha256 --ref-format=reftable` (throwaway repositories: a SHA-256 repository cannot exchange data with a SHA-1 repository, and GitHub needs SHA-1).
- **Example.** `git init shop`
- **Mistake.** Running it without a directory argument in the wrong place: every folder in your home directory shows as untracked, or a later `git add` says "adding embedded git repository".
- **Recover.** `git rev-parse --show-toplevel` tells you where you are; remove the stray `.git` after checking that it holds no commits you need.

### `git status` 🟢 · 4.4

- **Purpose.** Compares HEAD with the index and the index with the working tree, and reports the branch, its upstream and any operation in progress.
- **Forms.** `git status`, `git status -s` (`--short`), `git status -sb`, `git status --ignored`, `git status --porcelain`, `git status --porcelain=v2`, `git status --untracked-files=<mode>`.
- **Example.** `git status -sb`
- **Mistake.** Reading a clean status as "this tree equals the commit": ignored files and the assume-unchanged and skip-worktree bits are not shown (4.15, 5.12).
- **Recover.** `git status --ignored`, `git ls-files -v`; build release artifacts in a fresh clone or worktree.

### `git add` 🟢 · 5.3 to 5.8

- **Purpose.** Stores the current content of a file as a blob and writes that blob's ID into the path's index entry: a copy taken at that moment, not a subscription to the file.
- **Forms.** `git add <path>`, `git add -p`, `git add -N <path>` (intent-to-add), `git add -u`, `git add -A`, `git add .`, `git add -f <path>`, `git add -n <path>` (preview), `git add --chmod=+x <path>`, `git add --renormalize .` 🟡, `git add --sparse <path>`. `git add --resolved` was added in Git 2.56 (not run here).
- **Example.** `git add -p config/limits.yaml`
- **Mistake.** Editing the file after `git add` and committing: the commit lacks your latest edit.
- **Recover.** `git diff --cached` before every commit; `git add` again, then a new commit or `--amend`. Unstage with `git restore --staged <path>`.

### `git commit` 🟢 (🟡 for `--amend` and `--no-verify`) · 6.3, 6.7 to 6.9, 5.10

- **Purpose.** Turns the index into tree objects, wraps the top tree in a new commit object whose parent is the current HEAD commit, and moves the current branch to that object.
- **Forms.** `git commit -m <message>`, `git commit` (editor), `git commit -a`, `git commit <path>`, `git commit --dry-run`, `git commit --allow-empty`, `git commit -F <file>`, `git commit -s`, `git commit --trailer <key>=<value>` (Git 2.32 or later), `git commit --author=<author>`, `git commit --date=<date>`, `git commit -S` and `--no-gpg-sign`, `git commit --fixup=<commit>` and `--squash=<commit>` (9.7), `git commit --amend` with `--no-edit`, `--only`, `--reset-author`, `-C <commit>` 🟡, `git commit --no-verify` 🟡.
- **Example.** `git commit -m "Add rate limits"`
- **Mistake.** `git commit -a`, or a path argument, after partial staging: the commit contains the lines you left out with `-p`.
- **Recover.** `git reset HEAD~1` 🟡 while the commit is private, stage again, plain `git commit`. After an amend that went wrong: `git reset --soft 'HEAD@{1}'`.

### `git diff` 🟢 · 5.4, 14A.2 to 14A.6

- **Purpose.** Compares exactly two snapshots; every form differs only in which two it picks.
- **Forms.** `git diff` (index against working tree), `git diff --cached` (HEAD against index), `git diff HEAD`, `git diff <A> <B>`, `git diff <A>..<B>` (the same two endpoints), `git diff <A>...<B>` and `git diff --merge-base <A> <B>` (merge base against `<B>`), `-- <path>`; summaries `--stat`, `--shortstat`, `--numstat`, `--name-only`, `--name-status`, `--diff-filter=<letters>`; renames `-M[<n>%]`, `-C`, `--no-renames`; noise `-w`, `--word-diff`, `--ignore-cr-at-eol`; `--diff-algorithm=<name>`, `--patience`; `--check`; `--quiet`, `--exit-code`; during a conflict `--ours`, `--theirs`; `--submodule=log`; `--no-textconv`.
- **Example.** `git diff main...feature/streaming --stat`
- **Mistake.** Two dots, or two names, for a review: the diff shows deletions of things the branch never touched, because it compares the two tips.
- **Recover.** Nothing to recover; repeat with three dots or `--merge-base`.

### `git restore` 🔴 (🟡 for `--staged` alone) · 4.7, 11.3

- **Purpose.** Copies a stored version over working tree files, index entries, or both: from the index by default, from a commit with `--source`.
- **Forms.** `git restore <path>` 🔴, `git restore -p <path>` 🔴, `git restore --staged <path>` 🟡, `git restore --staged --worktree <path>` 🔴, `git restore --source=<commit> [--staged] [--worktree] <path>` 🔴, during a conflict `git restore --ours|--theirs|--merge <path>` 🔴 and `--conflict=<style>`. Older spelling: `git checkout -- <path>`.
- **Example.** `git restore --staged notes.txt`
- **Mistake.** `git restore <path>` without reading `git diff -- <path>` first; `git restore --source=<commit> .`, which deletes tracked paths the commit lacks.
- **Recover.** None for content that was never staged. Content that was staged at some point: `git fsck --lost-found`, then `git cat-file -p <id> > <path>`.

### `git rm` 🟡 (🔴 with `-f`) and `git mv` 🟢 · 4.8, 4.6

- **Purpose.** `git rm` deletes a file and its index entry; `git rm --cached` removes only the index entry; `git mv` renames the file and its index entry. Git records no rename: it is computed later from content (4.9).
- **Forms.** `git rm <path>`, `git rm -n <path>`, `git rm --cached <path>`, `git rm -f <path>` 🔴; `git mv <source> <destination>`, `git mv -n`.
- **Example.** `git rm --cached .env`
- **Mistake.** Believing that `.gitignore` stops tracking a file that is already tracked; and forgetting that the commit after `git rm --cached` deletes the path for everyone who pulls.
- **Recover.** `git restore --staged <path>` before committing; a teammate gets the file back with `git restore --source=<commit before> <path>`.

### `git stash` 🟡 (🔴 for `drop` and `clear`) · 11.11, 14C.2

- **Purpose.** Records the index and the working tree as commits that only `refs/stash` reaches, then resets both to HEAD.
- **Forms.** `git stash push [-m <message>] [-u] [--staged] [--keep-index] [-p] [-- <path>]`, `git stash list`, `git stash show -p [<entry>]`, `git stash apply [--index]`, `git stash pop [--index]`, `git stash branch <name>`, `git stash drop` 🔴, `git stash clear` 🔴, `git stash create` and `git stash store [-m <message>] <id>` 🟢, `git stash export --to-ref <ref>` and `git stash import` (Git 2.51 or later). `git stash save` is deprecated.
- **Example.** `git stash push -u -m "retry experiment"`
- **Mistake.** `git stash pop` without `--index` unstages what was staged; a pop that conflicts leaves the entry in the list; a dropped entry is lost once its unreachable commits are pruned.
- **Recover.** `git reset --merge`, then `git stash branch <name>`; after a drop, `git stash store -m "<message>" <id>` with the ID that `drop` printed.

### `git clean` 🔴 (🟢 with `-n`) · 4.14, 11.10

- **Purpose.** Deletes untracked files from the working tree: the one everyday command that removes data Git has no copy of.
- **Forms.** `git clean -n` (preview), `git clean -f`, `-d` (directories), `-X` (ignored files only), `-x` (ignored files as well), `-e <pattern>`, `-- <path>`.
- **Example.** `git clean -n -d -X -- build/`
- **Mistake.** Copying `git clean -fdx` from a "fix your build" answer in a repository where `data/`, `checkpoints/` and `.env` are ignored on purpose.
- **Recover.** None through Git.

### `git config` 🟡 for writes, 🟢 for reads · 14B.2 to 14B.4

- **Purpose.** Reads and writes configuration in the system, global, local and worktree scopes; the most specific scope wins, and the command line (`git -c <key>=<value>`) wins over all files.
- **Forms.** `git config get [--all] [--show-origin] [--show-scope] [--regexp] [--show-names] <key>`, `git config list [--show-origin] [--show-scope] [--global|--local|--file <file>]`, `git config set [--global|--local|--worktree] [--append] [--comment <text>] [--type=<type>] <key> <value>`, `git config unset [--global] [--value=<pattern>] <key>`, `git config edit`, `git config remove-section <name>`. All need Git 2.46 or later; the option forms `--get`, `--add`, `--unset`, `-l` are deprecated and still work.
- **Example.** `git config get --show-origin --show-scope pull.rebase`
- **Mistake.** A mistyped key (`pull.rebsae`) is stored without complaint and has no effect; a setting "does not take effect" because a more specific scope overrides it.
- **Recover.** `git config list --show-origin --show-scope`; check names against `git help --config`; `git config unset`.

### `git help`, `git version` 🟢 · 1.6, 1.7

- **Purpose.** The manual of the installed version, and the version itself.
- **Forms.** `git help <command>`, `git help -a`, `git help --config`, `git help glossary`, `git help datamodel` (Git 2.53 or later), `git --version`, `git version --build-options`.
- **Example.** `git version --build-options`
- **Mistake.** Running a command from this book with Apple's Git at `/usr/bin/git` (2.50.1) and getting "not a git command".
- **Recover.** Put the Homebrew directory first in `PATH`; print `git --version` at the top of scripts and CI logs.

## 3. History

### `git log` 🟢 · 14A.9 to 14A.15

- **Purpose.** Walks the commit graph from the tips you name, filters the commits it meets, and prints each survivor in the format you choose.
- **Forms.** Shape: `--oneline`, `--graph`, `--decorate`, `--all`, `--branches`, `--remotes`, `-<n>`, `--first-parent`, `--merges`, `--no-merges`, `--simplify-by-decoration`. Sets: `<A>..<B>`, `<A>...<B>` with `--left-right`, `--cherry-pick`, `--cherry-mark`, `--right-only`; `--not`, `--ancestry-path`, `--boundary`, `--reflog`, `-g`. Filters: `--author=`, `--committer=`, `--grep=` (with `-i`, `--all-match`), `--since=`, `--until=`, `-- <path>`, `--follow`, `--full-history`, `--diff-filter=`. Content: `-S<string>`, `-G<regex>`, `-L <start>,<end>:<file>`, `-L :<funcname>:<file>`. Output: `-p`, `--stat`, `--name-only`, `--name-status`, `--raw`, `--format=<format>`, `--date=<format>`, `--show-signature`. Merges: `--merge` (during a conflict), `--remerge-diff` (Git 2.36 or later).
- **Example.** `git log --oneline --graph --decorate --all`
- **Mistake.** Forgetting that the walk starts at HEAD: `-S` or `--grep` finds nothing although the code exists on another branch. `--since=<date>` without a time of day returns a strange subset. `-S` names a commit that only edited the line.
- **Recover.** State the walk (`--all`, or `--reflog`); give a full timestamp; check a pickaxe hit with `git show` and `-G`.

### `git show` 🟢 · 3.5, 6.12

- **Purpose.** Prints one object: a commit with its diff, a tag, a tree, or a file at a revision.
- **Forms.** `git show <commit>`, `git show --stat`, `git show -s --format=<format>` (`--no-patch`), `git show <commit>:<path>`, `git show :<n>:<path>` (index stage `<n>` during a conflict), `git show --remerge-diff <merge>`, `git show --first-parent <merge>`.
- **Example.** `git show HEAD~1:config/limits.yaml`
- **Mistake.** Reading `git show <merge>` (the combined diff) as "what the merge changed": it shows only lines that differ from every parent, so a resolution that took one side unchanged is invisible (8.16).
- **Recover.** Nothing to recover; audit the merge with `git show --remerge-diff <merge>`.

### `git shortlog` 🟢 · 14A.15

- **Purpose.** Groups commits by author, committer or trailer and counts them.
- **Forms.** `git shortlog -sn <revision>`, `-sne`, `--no-merges`, `--committer`, `--group=trailer:<key>` (Git 2.29 or later).
- **Example.** `git shortlog -sn --no-merges HEAD`
- **Mistake.** Omitting the revision in a script, a hook or a CI job: with standard input that is not a terminal, it reads a log from standard input and prints nothing.
- **Recover.** Always pass the revision.

### `git blame` 🟢 · 14A.16 to 14A.18

- **Purpose.** Annotates every line of a file, as it is in one revision, with the commit that last changed that line. It names the last change, not the cause.
- **Forms.** `git blame <path>`, `git blame <revision> -- <path>`, `-L <start>,<end>`, `-s`, `--date=<format>`, `-w`, `-M`, `-C` (repeatable), `--ignore-rev <commit>`, `--ignore-revs-file <file>`, `--first-parent`, `--line-porcelain`, `--diff-algorithm=<name>` (Git 2.53 or later).
- **Example.** `git blame -w -C -L 10,30 scoring/metrics.py`
- **Mistake.** Stopping at a formatting or squash commit that shows one author and one date for most lines; setting `blame.ignoreRevsFile` to a file that some commits lack, so that every blame fails.
- **Recover.** `-w`, `--ignore-rev`, or blame the branch; set the key with the `:(optional)` prefix.

### `git grep` 🟢 · 14A.23

- **Purpose.** Searches the content that Git tracks, in the working tree, the index or any revision, without checking it out.
- **Forms.** `git grep -n <pattern>`, `git grep <pattern> <revision> -- <path>`, `-l`, `-c`, `-i`, `-E`, `-W`, `-p`, `--cached`, `-q`.
- **Example.** `git grep -n "PASS_MARK" -- '*.py'`
- **Mistake.** In a sparse checkout, a search of the working tree "cannot find" code that exists (24.5).
- **Recover.** `git grep --cached`, or name a revision.

### `git describe` 🟢 · 14B.12, 24.11

- **Purpose.** Builds a version string from the nearest reachable tag, the number of commits since, and the abbreviated commit ID.
- **Forms.** `git describe`, `--tags` (lightweight tags too), `--match <pattern>`, `--exclude <pattern>`, `--dirty`, `--always`, `--exact-match`, `--contains`.
- **Example.** `git describe --tags --match 'v*' --dirty`
- **Mistake.** Running it in a shallow clone without tags: it fails in CI; without `--match` in a monorepo it answers with another project's tag.
- **Recover.** Fetch tags and full history in the versioning job (`git fetch --unshallow --tags`); add the pattern.

### `git range-diff` 🟢 · 9.14

- **Purpose.** Compares two versions of a series of commits: it pairs each old commit with its new counterpart and shows how the two patches differ.
- **Forms.** `git range-diff <base> <old-tip> <new-tip>`, `git range-diff <old-range> <new-range>`, `--creation-factor=<n>`.
- **Example.** `git range-diff main ORIG_HEAD HEAD`
- **Mistake.** Skipping it before pushing a rebased branch: a commit dropped in a conflict goes unnoticed.
- **Recover.** `git reset --hard <branch>@{1}` 🔴 and rebase again.

### `git cherry`, `git patch-id` 🟢 · 9.12, 10.10

- **Purpose.** Find commits whose change is already present elsewhere under another commit ID, by comparing patch IDs.
- **Forms.** `git cherry -v <upstream> [<head>]`, `git patch-id --stable` (reads a patch on standard input), `git log --cherry-mark --left-right <A>...<B>`.
- **Example.** `git cherry -v release/1.2 main`
- **Mistake.** Relying on patch IDs alone: `git cherry` shows `+` for a commit that was backported with a conflict, because the patch differs.
- **Recover.** Search for the `(cherry picked from commit ...)` line that `-x` records.

### `git rev-list`, `git merge-base` 🟢 · 7.8, 8.2, 14A.8

- **Purpose.** `git rev-list` lists the commits a revision expression selects; `git merge-base` prints the best common ancestor of two commits.
- **Forms.** `git rev-list --count <range>`, `git rev-list --left-right --count <A>...<B>`, `--first-parent`, `--no-merges`, `--max-parents=<n>`, `--all`, `--objects`, `--missing=print`; `git merge-base <A> <B>`, `--all`, `--is-ancestor <A> <B>`, `--fork-point`.
- **Example.** `git merge-base --is-ancestor <commit> origin/main && echo merged`
- **Mistake.** Treating the exit status of `--is-ancestor` as an error: status 1 means "not an ancestor". After a squash merge it also says "not merged", because the squash commit is a new commit.
- **Recover.** Compare trees for squash merges: `git merge-tree --write-tree main <branch>` (7.13).

### `git last-modified` 🟢, experimental, Git 2.52 or later · 14D.8

- **Purpose.** Shows, for each path of a tree, the commit that last changed it.
- **Forms.** `git last-modified`, `git last-modified -r`, `-- <path>`.
- **Example.** `git last-modified -r -- gateway/`
- **Mistake.** Adopting it in shared automation: the manual carries the word EXPERIMENTAL, so output and options may change between releases, and Apple's Git 2.50.1 does not have it.
- **Recover.** Use it at the keyboard; pin the Git version where a script depends on it.

### `git whatchanged` (deprecated) · 14A.24

- **Purpose.** An old spelling of `git log --raw --no-merges`.
- **Forms.** On Git 2.55 it stops with "refusing to run without --i-still-use-this"; removal is planned for Git 3.0.
- **Example.** `git log --raw --no-merges -2`
- **Mistake.** Keeping it in scripts.
- **Recover.** Replace it with the `git log` form.

## 4. Branches and integration

### `git branch` 🟢 to create and list, 🟡 for `-m`, `-f`, `-d`, `-u`, 🔴 for `-D` · 7.5, 7.13

- **Purpose.** Lists, creates, renames, moves and deletes branches. A branch is a ref: one name that holds one commit ID.
- **Forms.** `git branch`, `git branch -vv`, `-a`, `-r`, `--show-current` (Git 2.22 or later; prints nothing in detached HEAD), `--list <pattern>`, `--merged [<commit>]`, `--no-merged`, `--contains <commit>`, `-r --contains <commit>`, `--format=<format>`; `git branch <name> [<start>]` 🟢; `git branch -m <new>` 🟡; `git branch -f <name> <commit>` 🟡; `git branch -u <upstream>` and `--unset-upstream` 🟡; `git branch -d <name>` 🟡; `git branch -D <name>` 🔴. Git 2.56 adds `--delete-merged` and `--forked <branch>` (not run here).
- **Example.** `git branch rescue/before-reset <id>`
- **Mistake.** Reading the refusal of `-d` after a squash merge as an error and reaching for `-D` without checking: the squash commit is a new commit, so Git cannot see the branch as merged.
- **Recover.** `git branch <name> <id>` with the ID from the `Deleted branch <name> (was <id>)` line, or from the HEAD reflog.

### `git switch` 🟢 (🟡 for `-C`, 🔴 for `--discard-changes`), and `git checkout` · 7.6, 7.7

- **Purpose.** Changes which branch HEAD names and updates the index and the working tree to that branch's commit, refusing when a local change would be lost.
- **Forms.** `git switch <branch>`, `git switch -c <new> [<start>]`, `git switch -C <name> [<start>]` 🟡, `git switch --detach <commit>`, `git switch -`, `git switch --orphan <new>`, `git switch --merge <branch>` (since Git 2.55 it saves the local changes in a stash and reapplies them), `git switch --no-overwrite-ignore <branch>`, `git switch --discard-changes <branch>` 🔴. Older spellings to read in scripts: `git checkout <branch>`, `git checkout -b <new>`, `git checkout -B`, `git checkout --detach`, `git checkout -f` 🔴.
- **Example.** `git switch -c feature/streaming main`
- **Mistake.** Committing on a detached HEAD and switching away: the commits "disappear" because no branch names them.
- **Recover.** `git reflog` shows the `checkout:` line; `git branch <name> <id>` (Lab 4.2).

### `git tag` 🟢 to create, 🟡 for `-f` and `-d` · 7.11, 14B.8 to 14B.11

- **Purpose.** Creates, lists, verifies and deletes tags: a lightweight tag is a ref to a commit; an annotated or signed tag is a tag object that a ref points to.
- **Forms.** `git tag <name> [<commit>]`, `git tag -a <name> -m <message> [<commit>]`, `git tag -s <name>`, `git tag -l '<pattern>'` (`--list`), `git tag --sort=version:refname`, `git tag -n1`, `--contains <commit>`, `--no-contains`, `--merged`, `--points-at <commit>`, `git tag -v <name>`, `git tag -f <name> <commit>` 🟡, `git tag -d <name>` 🟡.
- **Example.** `git tag -a v1.0.0 -m "inference-gateway 1.0.0"`
- **Mistake.** Moving a tag that was already pushed: two machines then disagree about what the name means, and tags have no reflog.
- **Recover.** Restore the published tag and release a new version; on clones that fetched the moved tag, `git fetch --tags --force` after confirming that the server is right.

### `git merge` 🟡 (🔴 for `--abort`) · 8.3 to 8.14

- **Purpose.** Joins another history into the current branch: by moving the ref (fast-forward) or by a three-way merge that creates a commit with two parents.
- **Forms.** `git merge <other>`, `--ff-only`, `--no-ff`, `--no-commit`, `--squash`, `-m <message>`, `--autostash`, `-X ours`, `-X theirs`, `-X ignore-space-change`, `-s ours`, `--allow-unrelated-histories`, `--verify-signatures`, `git merge --continue`, `git merge --quit`, `git merge --abort` 🔴.
- **Example.** `git merge --no-ff feature/rouge`
- **Mistake.** Resolving with a whole-file `--ours` or `--theirs` when only some hunks conflict: a teammate's change vanishes. Committing conflict markers.
- **Recover.** Before pushing: `git reset --merge ORIG_HEAD` (check `ORIG_HEAD` first, or take the commit from the reflog). After pushing: `git revert -m 1 <merge>` (and read 11.9 before merging that branch again). `git diff --cached --check` finds markers.

### `git merge-tree` 🟢 · 8.17

- **Purpose.** Performs a merge without a working tree or index and prints the resulting tree ID and any conflicts; it adds unreferenced objects only.
- **Forms.** `git merge-tree --write-tree <A> <B>` (Git 2.38 or later), `--name-only`, `--merge-base=<commit>`, `--no-messages`, `--quiet` (Git 2.50 or later: only checks whether the merge is clean).
- **Example.** `git merge-tree --write-tree --name-only HEAD feature/rouge`
- **Mistake.** Using the three-argument form `git merge-tree <base> <branch1> <branch2>`, a trivial-merge mode that the manual calls deprecated.
- **Recover.** Nothing to recover.

### `git rebase` 🟡 · 9.2 to 9.13

- **Purpose.** Takes the commits your branch has and `<upstream>` lacks, creates a copy of each on top of `<upstream>`, in order, and then points your branch at the last copy. Every copy has a new ID.
- **Forms.** `git rebase <upstream>`, `git rebase --onto <new-base> <old-base> [<branch>]`, `-i`, `--autosquash` (without `-i` since Git 2.44), `--autostash`, `--update-refs` (Git 2.38 or later), `--rebase-merges`, `--keep-base`, `--root`, `--exec <command>`, `-X <option>`, `--reapply-cherry-picks`, `--trailer` (Git 2.54 or later), `--apply`; while stopped: `--continue`, `--skip`, `--abort`, `--quit`, `--edit-todo`, `--show-current-patch`.
- **Example.** `git rebase --onto main feature/base feature/top`
- **Mistake.** Forgetting the swap: during a rebase "ours" is the new base plus the copies made so far and "theirs" is your own commit. Using `git commit --amend` at a conflict stop, which puts the resolution into the wrong commit.
- **Recover.** `git reset --hard <branch>@{1}` 🔴 or `git reset --keep ORIG_HEAD`, then redo; prefer `<branch>@{1}`, because `ORIG_HEAD` is rewritten by later commands. Review with `git range-diff` before every push.

### `git cherry-pick` 🟡 · 10.2 to 10.9

- **Purpose.** Takes the difference between a commit and its parent, merges that difference into the current branch with a three-way merge, and commits the result as a new commit with a new ID.
- **Forms.** `git cherry-pick <commit>`, `git cherry-pick <A>..<B>`, `-x`, `-e`, `-n`, `-m 1 <merge>`, `--empty=drop|keep|stop` (Git 2.45 or later), `--continue`, `--skip`, `--abort`, `--quit`.
- **Example.** `git cherry-pick -x <id>`
- **Mistake.** Backporting without `-x`: later `git branch --contains` says the fix is not in the release, because the copy has another ID. Picking a merge commit without `-m`.
- **Recover.** `git cherry-pick --abort` during a sequence; `git reset --keep ORIG_HEAD` or the branch reflog before pushing; `git revert` after.

### `git worktree` 🟢 to add, 🟡 for `remove`, `move`, `prune`, 🔴 with `--force` · 25.2 to 25.6

- **Purpose.** Creates further directories of checked-out files that belong to the same repository: the same objects and refs, with a HEAD and an index of their own.
- **Forms.** `git worktree add <path> <branch>`, `git worktree add -b <new> <path> [<start>]`, `git worktree add --detach <path> <commit>`, `git worktree add --relative-paths` (Git 2.48 or later), `git worktree list [--verbose|--porcelain]`, `git worktree lock --reason <text> <path>`, `unlock`, `move` 🟡, `remove` 🟡, `remove --force` 🔴, `prune [--dry-run --verbose]` 🟡, `repair [<path>]`.
- **Example.** `git worktree add --detach ../rag-api-v1.3.0 v1.3.0`
- **Mistake.** Deleting a worktree directory with `rm -rf`: the entry stays, and the branch "is used by worktree" at a path that no longer exists.
- **Recover.** `git worktree prune`, then delete the branch; `git worktree repair` after a directory was moved by hand.

## 5. Remotes

### `git remote` 🟢 to read and add, 🟡 to change · 12.2, 12.10

- **Purpose.** Manages remotes: named URLs with a fetch refspec, stored in the repository's configuration.
- **Forms.** `git remote -v`, `git remote show <name>`, `git remote get-url <name>`, `git remote add <name> <url>`, `git remote set-url [--push] <name> <url>` 🟡, `git remote set-head <name> --auto` 🟡, `git remote set-branches [--add] <name> <branch>` 🟡, `git remote rename` 🟡, `git remote remove` 🟡, `git remote prune [--dry-run] <name>` 🟡, `git remote update`.
- **Example.** `git remote add upstream <url>`
- **Mistake.** In a single-branch clone, `git switch <branch>` fails with `invalid reference` although the server has the branch: the fetch refspec is narrow.
- **Recover.** `git remote set-branches --add origin <branch>`, then fetch.

### `git clone` 🟢 · 12.3, 26.11 to 26.13

- **Purpose.** Creates a new repository, registers the source as the remote `origin`, fetches everything the default refspec covers, and checks out one branch.
- **Forms.** `git clone <url> [<directory>]`, `--origin <name>`, `--branch <name>`, `--single-branch`, `--no-checkout`, `--bare`, `--mirror`, `--depth <n>` (shallow), `--filter=blob:none` and `--filter=tree:0` (partial), `--sparse`, `--recurse-submodules`, `--no-local`, `--reject-shallow`, `--bundle-uri=<uri>` (Git 2.38 or later).
- **Example.** `git clone --filter=blob:none --sparse <url>`
- **Mistake.** `--depth 1` for a job that needs history: versions, blame and changelogs are wrong, or CI fails with `no merge base`.
- **Recover.** `git fetch --unshallow`, or a blobless clone; shallow only for snapshot jobs.

### `git fetch` 🟢 (🟡 with `--prune` or `--tags --force`, 🔴 with `--prune --prune-tags`) · 12.4, 12.11

- **Purpose.** Asks a remote where its refs point, downloads the objects you lack, and moves your remote-tracking refs to match; it never moves a local branch, the index or the working tree.
- **Forms.** `git fetch [<remote>]`, `git fetch <remote> <branch>`, `git fetch <remote> <src>:<dst>` (for example `pull/N/head:pr-N` on GitHub, 17.2), `--dry-run`, `--tags`, `--prune` 🟡, `--tags --force` 🟡, `--prune --prune-tags` 🔴, `--depth <n>`, `--deepen=<n>`, `--unshallow`, `--refetch`.
- **Example.** `git fetch --prune origin`
- **Mistake.** Deciding from `origin/main` without fetching: remote-tracking refs are a cache of the last contact. Being "up to date" locally while teammates see newer commits.
- **Recover.** `git fetch`; the previous value of a remote-tracking ref is `origin/<branch>@{1}` in its reflog, unless the ref was pruned.

### `git pull` 🟡 · 12.6, 9.13

- **Purpose.** `git fetch` followed by one integration of the fetched upstream into the current branch: a fast-forward, a merge or a rebase; when the two branches have diverged, Git makes you say which.
- **Forms.** `git pull`, `git pull --ff-only`, `git pull --rebase`, `git pull --no-rebase`, `git pull --autostash`, `git pull --recurse-submodules`.
- **Example.** `git pull --ff-only`
- **Mistake.** Pulling with rebase after someone's forced push, which can drop commits; pulling in automation, which can create merge commits nobody reviewed.
- **Recover.** `git reset --hard ORIG_HEAD` 🔴 as the very next command, or the branch reflog. Prefer `git fetch`, look with `git log --oneline --graph HEAD @{u}`, then integrate.

### `git push` 🟡 (🔴 for forced, deleting and mirroring forms) · 12.5, 12.7, 12.8

- **Purpose.** Asks a remote to make some of its refs point at commits of yours, sends the objects it lacks, and succeeds for each ref only if both your Git and the remote accept the update.
- **Forms.** `git push`, `git push -u origin <branch>`, `git push <remote> <src>:<dst>`, `--dry-run`, `--atomic`, `--follow-tags`, `git push origin <tag>`, `--tags`, `--recurse-submodules=check|on-demand`, `--no-verify`; 🔴 `git push <remote> --delete <ref>`, `git push <remote> :<ref>`, `--force-with-lease[=<ref>[:<expect>]]`, `--force-if-includes` (Git 2.30 or later), `--force` (`-f`, `+<ref>`), `--mirror`, `--prune`.
- **Example.** `git push --force-with-lease --force-if-includes`
- **Mistake.** Answering `! [rejected] ... (non-fast-forward)` with `--force`. Reading `Everything up-to-date` as "my commit is on the server" when another branch, or a detached HEAD, holds the commit.
- **Recover.** Integrate (`git rebase @{u}` or `git merge @{u}`) and push again. After a wrong forced push: the old tip from any clone that had it, pushed back (12.8, 13.10).

### `git ls-remote` 🟢 · 12.4

- **Purpose.** Lists the refs a remote has now, without changing anything locally.
- **Forms.** `git ls-remote <remote>`, `--branches` (Git 2.46 or later; `--heads` is the deprecated synonym), `--tags`, `--symref <remote> HEAD`.
- **Example.** `git ls-remote --tags origin`
- **Mistake.** Skipping it and trusting `git branch -r`, which shows what the last fetch saw.
- **Recover.** Nothing to recover.

### `git bundle` 🟢 · 13.14, 26.14

- **Purpose.** Writes refs and the objects they reach into one file that can be verified, moved and fetched from.
- **Forms.** `git bundle create <file> --all`, `git bundle create <file> <old>..<new>`, `git bundle verify <file>`, `git bundle list-heads <file>`.
- **Example.** `git bundle create ../evidence/repo.bundle --all`
- **Mistake.** Applying an incremental bundle where its basis is missing: `Repository lacks these prerequisite commits`. Expecting a bundle to hold reflogs, unreachable objects, the index or uncommitted files.
- **Recover.** Apply the missing bundle first, or cut a new one from what the other site has.

### `git submodule` 🟢 to add and inspect, 🟡 for `update` and `deinit`, 🔴 with `--force` · 23.2 to 23.11

- **Purpose.** Records another repository at a fixed commit inside yours: a gitlink in the tree, a URL in `.gitmodules`, a repository under `.git/modules`.
- **Forms.** `git submodule add <url> <path>`, `git submodule status`, `git submodule summary`, `git submodule init`, `git submodule update [--init] [--recursive]` 🟡, `update --remote` 🟡, `update --force` 🔴, `git submodule foreach '<command>'`, `git submodule sync`, `set-url`, `set-branch`, `deinit <path>` 🟡; with other commands: `git clone --recurse-submodules`, `git pull --recurse-submodules`, `git push --recurse-submodules=check`, `git diff --submodule=log`.
- **Example.** `git submodule update --init --recursive`
- **Mistake.** Pushing the superproject before the submodule commit it points at (`not our ref`); committing a stale gitlink with `git commit -a` after a pull, which rolls the dependency back silently.
- **Recover.** Push the library commit, or move the pointer to a published commit; `git submodule update` after every pull that moved a gitlink.

### `git subtree` 🟡 (🟢 for `split`) · 23.13

- **Purpose.** Copies another project's files into a subdirectory of your own history, and merges later versions.
- **Forms.** `git subtree add --prefix=<dir> <repository> <ref> --squash`, `git subtree pull --prefix=<dir> <repository> <ref> --squash`, `git subtree push --prefix=<dir> <repository> <branch>`, `git subtree split --prefix=<dir> [-b <branch>]`.
- **Example.** `git subtree pull --prefix=vendor/textsplit <repository> main --squash`
- **Mistake.** A pull without `--squash` after an add with it: `refusing to merge unrelated histories`.
- **Recover.** Repeat the pull with `--squash`; undo an unpushed add or pull with `git reset --hard ORIG_HEAD` 🔴.

### `git lfs` (a separate program; git-lfs 3.7.1 here) · 22.3 to 22.9

- **Purpose.** Replaces large files in commits by small pointer files, through a clean and a smudge filter, and keeps the content in a separate store.
- **Forms.** `git lfs install --local` 🟢 (without `--local` it writes your global configuration 🟡), `git lfs track "<pattern>"`, `untrack`, `git lfs ls-files [--size] [--all]`, `git lfs status`, `git lfs env`, `git lfs fetch [--all]`, `git lfs pull`, `git lfs checkout`, `git lfs push [--all] <remote> <ref>` 🟡, `git lfs prune [--dry-run --verbose --verify-remote]` 🟡, `git lfs fsck [--pointers]`, `git lfs pointer --file=<file>`, `git lfs migrate info|import|export` with `--include=<pattern>`, `--above=<size>`, `--everything` (🟡; 🔴 with `--everything` and a forced push), `git lfs uninstall`. `git lfs clone` is deprecated.
- **Example.** `git lfs migrate info --above=1mb`
- **Mistake.** Tracking a pattern after the file was committed: it stays an ordinary blob in history. Working without the client installed: programs read 130-byte pointer files.
- **Recover.** `git add --renormalize <path>` and commit, or `git lfs migrate import` on unpushed commits; `git lfs install --local`, then `git lfs pull`.

## 6. Undo

The decision between these commands is Chapter 11, section 11.2 (four places and one deciding question) and section 11.12 (one table and one decision tree). `git restore`, `git commit --amend`, `git clean` and `git stash` are in section 2 above.

### `git reset` 🟡 for `--soft`, `--mixed`, `--keep` and paths, 🔴 for `--hard` and `--merge` · 11.4 to 11.6

- **Purpose.** Makes the current branch point at `<commit>`; the mode decides whether the index (`--mixed`, the default) and the working tree (`--hard`) are rewritten to match.
- **Forms.** `git reset --soft <commit>`, `git reset [--mixed] <commit>`, `git reset --keep <commit>`, `git reset --merge [<commit>]` 🔴, `git reset --hard [<commit>]` 🔴, `git reset [--] <path>` and `git reset -p` (index entries only).
- **Example.** `git reset --keep rescue/before-reset`
- **Mistake.** `--hard` with uncommitted work in the tree; `git reset --hard ORIG_HEAD` several commands later, when `ORIG_HEAD` names something else.
- **Recover.** Commits: the reflog (`git reset --keep <branch>@{1}`). Staged content: `git fsck --lost-found`. Unstaged content: none. Use `--keep`, not `--hard`.

### `git revert` 🟡 · 11.8, 11.9, 10.11

- **Purpose.** Adds a commit whose change is the opposite of what `<commit>` changed, and removes nothing: the undo for history that others already have.
- **Forms.** `git revert <commit>`, `--no-edit`, `-n`, `git revert -m 1 <merge>`, `--continue`, `--skip`, `--abort`, `--quit`.
- **Example.** `git revert --no-edit <id>`
- **Mistake.** Reverting a merge and later merging the same branch again: Git considers those commits merged, so most of the branch's changes are missing.
- **Recover.** Revert the revert and merge again, or recreate the branch (11.9); put the re-merge procedure into the revert message.

## 7. Recovery

The method is Chapter 13, section 13.7: stop, look, anchor the lost state with a ref, then recover with the mildest command. The one-page version is the [emergency recovery page](../cheatsheets/emergency-recovery-one-page.md); the full procedures are in the [disaster-recovery playbook](../playbooks/disaster-recovery-playbook.md).

### `git reflog` 🟢 to read, 🔴 for `expire`, `delete`, `drop` · 13.3, 13.4

- **Purpose.** Shows the local record of every value a ref had and the command that set it. HEAD has one, each branch has one; tags and remote-tracking refs have none by default, and a fresh clone starts empty.
- **Forms.** `git reflog`, `git reflog show <ref>`, `git reflog -<n>`, `--date=<format>`, `git reflog list` (Git 2.45 or later), `git reflog exists <ref>`, `git log -g [--grep-reflog=<pattern>]`; selectors `<ref>@{<n>}` and `<ref>@{<time>}`; 🔴 `git reflog expire [--expire=<time>] [--expire-unreachable=<time>] [--all] [--dry-run] [--verbose]`, `git reflog delete <ref>@{<n>}`, `git reflog drop <ref>` (Git 2.50 or later).
- **Example.** `git reflog show feature/streaming`
- **Mistake.** Looking for the reflog of a deleted branch (`unknown revision`), or expecting one on a CI runner.
- **Recover.** The HEAD reflog, the printed `(was <id>)` line, or `git fsck --no-reflogs`.

### `git fsck` 🟢 · 3.8, 13.6

- **Purpose.** Checks the object database and, as a search tool, lists objects that no ref and no reflog entry reaches.
- **Forms.** `git fsck`, `git fsck --dangling` (the default report), `--unreachable`, `--no-reflogs`, `--lost-found` (writes copies under `.git/lost-found/`).
- **Example.** `git fsck --lost-found`
- **Mistake.** Reading `dangling commit` as corruption. It is information: an object without a name.
- **Recover.** `git branch rescue/<what> <id>` to keep it; nothing otherwise. `missing blob` or `broken link` is damage: restore the object from another clone (13.11).

### Anchors and backups 🟢 · 13.7, 13.14, 29.7

- **Purpose.** Give a state a name before anything moves, so that no expiry and no collection can touch it.
- **Forms.** `git branch rescue/<what> <id>`, `git tag <name> <id>`, `git update-ref refs/backup/<name> <id>`, `git stash store -m <message> <id>`, `git bundle create <file> --all`, `cp -Rp . ../evidence/<name>-copy` (the only one that keeps reflogs, the index and uncommitted files).
- **Example.** `git branch rescue/before-rebase`
- **Mistake.** Running a second fix, `git gc`, `git fetch --prune` or a re-clone before the lost state has a name.
- **Recover.** `git branch -D` or `git update-ref -d` removes an anchor you no longer need.

## 8. Debugging

The fixed opening of every diagnosis is the ten-command sequence of Chapter 1, section 1.11; Chapter 29, section 29.5 lists the commands that test a hypothesis, all 🟢. See also the [troubleshooting playbook](../playbooks/troubleshooting-playbook.md).

### `git bisect` 🟡 · 14A.20 to 14A.22

- **Purpose.** Finds the commit that changed a property by checking out a commit in the middle of the suspects, asking for a verdict, and halving the suspects until one is left.
- **Forms.** `git bisect start [<bad> [<good>]]`, `git bisect good [<commit>]`, `git bisect bad [<commit>]`, `git bisect skip`, `git bisect run <command>` (exit status 0 means good and 125 means skip; the full protocol is 14A.21), `git bisect log`, `git bisect replay <file>`, `git bisect reset`, `git bisect terms`, `git bisect visualize`, `git bisect start --term-old <word> --term-new <word>`, `--first-parent`, `--no-checkout` 🟢. `--reset-when-found` is a Git 2.56 addition (not run here).
- **Example.** `git bisect run ./test-regression.sh`
- **Mistake.** A test script that fails for a reason other than the bug (a commit that does not build): bisect then names a commit that cannot be the cause.
- **Recover.** Edit the saved log, `git bisect reset`, `git bisect replay <file>`; exit 125 for untestable commits. `git bisect reset` always returns you to the starting branch.

### Pickaxe, line history and blame · 14A.11, 14A.12, 14A.16, 14A.19

The search commands are forms of `git log` and `git blame` (section 3): `git log -S<string>` (the number of occurrences changed), `git log -G<regex>` (a changed line matches), `git log -L <range>:<file>` (the history of lines), `git blame` (the last change per line). The method that combines them is section 14A.19.

### Diagnosis commands, all 🟢

| Command | Purpose | Forms taught | Example | Common mistake | Recover | Section |
|---|---|---|---|---|---|---|
| `git rev-parse` | Turns a name into an object ID, and answers questions about the repository | `<rev>`, `--short`, `--verify`, `--abbrev-ref HEAD`, `--symbolic-full-name @{u}`, `--show-toplevel`, `--git-dir`, `--git-common-dir`, `--git-path <path>`, `--is-inside-work-tree`, `--is-bare-repository`, `--is-shallow-repository`, `--show-object-format`, `--show-ref-format`, `--show-prefix` | `git rev-parse --verify refs/heads/main` | Reading `.git/refs/heads/<branch>` in a script: the ref may be packed, or stored as reftable | Use `git rev-parse` | 3.6 |
| `git ls-files` | Reads the index | `--stage` (`-s`), `-u` (`--unmerged`), `--others --exclude-standard`, `--ignored`, `--modified`, `--deleted`, `-v`, `-t`, `--eol`, `--debug`, `--sparse`, `--error-unmatch`, `--format=<format>` (Git 2.38 or later) | `git ls-files --stage` | Overlooking a lowercase letter in `-v` output: it marks an assume-unchanged entry | The `--no-assume-unchanged` form of `git update-index` | 5.11, 5.12 |
| `git check-ignore` | Explains which pattern ignores a path | `-v <path>`, `-v -n <path>`, `--no-index` | `git check-ignore -v build/out.log` | Expecting an answer for a tracked file: tracked files are not ignored | `--no-index`; then `git rm --cached` | 4.5, 4.6 |
| `git check-attr` | Shows which attributes apply to a path | `git check-attr -a -- <path>`, `git check-attr <attribute> -- <path>` | `git check-attr -a -- model.onnx` | Assuming a driver named in `.gitattributes` is defined on this machine: attributes travel, drivers do not | Define the driver in configuration | 14C.4 |
| `git var` | Prints the values Git will use | `git var GIT_AUTHOR_IDENT`, `GIT_DEFAULT_BRANCH`, `GIT_CONFIG_GLOBAL`, `GIT_CONFIG_SYSTEM` | `git var GIT_AUTHOR_IDENT` | Checking `user.email` only, when an environment variable or an include overrides it | `git config get --all --show-origin user.email` | 14B.2, 14B.4 |
| `git count-objects` | Counts loose objects and packs | `git count-objects -v` | `git count-objects -v` | Ignoring a count of hundreds of packs or thousands of loose objects | `git maintenance run` | 3.7, 26.2, 26.16 |
| `git diff --check` | Finds conflict markers and whitespace errors | `git diff --check`, `git diff --cached --check` | `git diff --cached --check` | Concluding a merge without it | Remove the markers in a new commit | 8.10, 14A.6 |
| `git url-parse` (Git 2.55 or later) | Splits a remote URL into its parts | `git url-parse -c <component> <url>` | `git url-parse -c host git@github.com:acme/support-bot.git` | Using it in scripts that run on older Gits | Not needed | 12.13 |

### Trace variables 🟢 · 14B.7, 26.2

| Variable | Shows | Use it when |
|---|---|---|
| `GIT_TRACE=1` | Alias expansion, built-in and external commands that are started | "What did that command actually run?" |
| `GIT_TRACE_SETUP=1` | The `.git` directory, the working tree, the current directory and prefix Git settled on | Git picks up the wrong repository, or none |
| `GIT_TRACE_PACKET=1` | The protocol conversation with a remote | Fetch and push puzzles (12.13) |
| `GIT_TRACE_CURL=1`, `GIT_CURL_VERBOSE=1` | The HTTP exchange: requests, response codes, headers | HTTPS authentication and proxy failures (Chapter 16) |
| `GIT_SSH_COMMAND='ssh -v ...'` | Replaces the `ssh` program and its options for this command | SSH picks the wrong key |
| `GIT_TRACE2_PERF=1` | A table of what a command did and how long each part took | Finding where one command spends its effort (26.2) |

A trace can print credentials and paths: read it before you paste it anywhere.

## 9. Advanced

### `git rerere` 🟢 to inspect, 🟡 for `forget`, `clear`, `gc` · 14C.3

- **Purpose.** Records how you resolved a conflict and replays the resolution when the same conflict text appears again.
- **Forms.** Enable with `git config set rerere.enabled true`; `git rerere`, `git rerere status`, `git rerere diff`, `git rerere remaining`, `git rerere forget <path>` 🟡, `git rerere clear` 🟡, `git rerere gc` 🟡.
- **Example.** `git rerere forget retrieval.yaml`
- **Mistake.** A wrong resolution is replayed as faithfully as a right one; with `rerere.autoUpdate` it is also staged. On Git 2.55 the background `rerere-gc` maintenance task can make a rebase die with `Unable to create ... MERGE_RR.lock`.
- **Recover.** `git rerere forget <path>`, `git restore --merge <path>` 🔴, resolve again; set `maintenance.rerere-gc.auto` to `0` where you rebase with rerere.

### `git hook` 🟡, and `--no-verify` · 14C.9 to 14C.13

- **Purpose.** Lists and runs the programs Git starts at fixed points (`pre-commit`, `commit-msg`, `pre-push` and others). Hooks are local: they are not cloned, and they cannot enforce policy.
- **Forms.** `git hook list [--show-scope] <event>`, `git hook run <event>`, `git config set core.hooksPath <dir>`; `git commit --no-verify`, `git push --no-verify`. `git hook` exists since Git 2.36, configuration-defined hooks since 2.54, parallel execution since 2.55.
- **Example.** `git hook list --show-scope pre-commit`
- **Mistake.** Treating a hook as enforcement: a secret or a WIP commit reaches `main` despite it, because `--no-verify` and a clone without the hook skip it.
- **Recover.** Enforce on the server: rulesets, push protection, required checks (Chapter 18, Chapter 21B).

### `git sparse-checkout` 🟡 (🔴 for `clean -f`) · 24.4 to 24.6

- **Purpose.** Limits the working tree to a set of directories (the cone); the index and the history still hold the whole repository.
- **Forms.** `git sparse-checkout set <directories>`, `add <directories>`, `list` 🟢, `reapply`, `disable`, `set --sparse-index` and `--no-sparse-index`, `clean --dry-run`, `clean -f` 🔴 (Git 2.52 or later); `git clone --sparse`; `git add --sparse`. `init --cone` is deprecated: `set` does everything. The command as a whole is labelled experimental in the manual.
- **Example.** `git sparse-checkout set services/gateway libs/schemas`
- **Mistake.** Narrowing the cone while ignored files you cannot regenerate (a local `.env`, a downloaded evaluation set) live in directories that leave it: they are deleted.
- **Recover.** None from Git for those files; `git status --short --ignored` first.

### `git maintenance`, `git gc`, `git prune`, `git repack` 🟡 (🔴 for `git gc --prune=now`, `git prune`, `git repack -a -d`) · 26.3 to 26.5, 13.13

- **Purpose.** Keep the object database fast: pack loose objects, consolidate packs, write the commit-graph and the multi-pack-index, expire reflog entries, and delete unreachable objects after the grace period.
- **Forms.** `git maintenance run [--auto] [--task=<task>]`, `git maintenance is-needed [--auto] [--task=<task>]` (Git 2.53 or later), `git maintenance start`, `stop`, `register`, `unregister`; `git gc`, `git gc --prune=<date>`; `git prune -n`, `git prune --expire=<time>`; `git repack -a -d`, `git repack --geometric=<factor> -d`. Git 2.56 adds `git repack --drop-filtered` (not run here).
- **Example.** `git maintenance run --task=commit-graph`
- **Mistake.** Following "run `git gc --prune=now --aggressive` to fix a slow repository": it deletes the safety net as a side effect. Running `git gc` beside a maintenance process.
- **Recover.** None for what was deleted; another clone or a backup. Automatic maintenance (geometric strategy, the default since Git 2.54) needs no command.

### Derived files, partial clone and Scalar

| Command | Risk | Purpose | Forms taught | Example | Common mistake | Recover | Section |
|---|---|---|---|---|---|---|---|
| `git commit-graph` | 🟢 | Writes and checks the file that speeds up history walks | `write --reachable [--changed-paths]`, `verify` | `git commit-graph write --reachable --changed-paths` | Copying the file between repositories by hand | Delete `objects/info/commit-graph` or `commit-graphs/` and write it again | 26.6 |
| `git multi-pack-index` | 🟢 | Writes and checks one index over several packs | `write`, `verify` | `git multi-pack-index write` | Treating it as data: it is derived | Delete the file | 26.7 |
| `git backfill` (experimental, Git 2.49 or later) | 🟢 | Downloads missing blobs of a partial clone in batches | `git backfill`, `git backfill --sparse` | `git backfill --sparse` | Going offline in a blobless clone without it: `could not fetch <id> from promisor remote` | Reconnect and repeat | 24.7, 26.12 |
| `scalar clone` | 🟡 | A partial, sparse clone plus global configuration, a scheduler and a monitor daemon | `scalar clone <url>`, `--no-maintenance`, `scalar unregister`, `scalar delete` | `scalar clone --no-maintenance <url>` | Not knowing what it configured: an unexplained daemon and scheduler entries | `scalar unregister`; `git fsmonitor--daemon stop` | 24.7 |
| `git fsmonitor--daemon` | 🟢 for `status` | Reports or stops the file-system monitor | `status`, `stop` | `git fsmonitor--daemon status` | Not knowing that one runs, after `scalar clone` | `git fsmonitor--daemon stop` | 24.7, 26.9 |
| `git refs` | 🟡 for `migrate` | Converts the ref storage format; checks refs | `git refs migrate --ref-format=<format> [--dry-run]` (Git 2.46 or later), `git refs verify`, `git refs list` | `git refs migrate --ref-format=reftable --dry-run` | Migrating a repository that tools read through `.git/refs` files | Migrate back with `--ref-format=files` | 3.13, 14D.5 |

### History rewriting and patches

| Command | Risk | Purpose | Forms taught | Example | Common mistake | Recover | Section |
|---|---|---|---|---|---|---|---|
| `git history` (experimental; Git 2.54, `fixup` 2.55) | 🟡 | Rewrites one commit and moves every descendant local branch | `reword <commit>`, `fixup <commit>`, `split <commit>`, `--dry-run`; `drop` was added in Git 2.56 (not run here) | `git history reword --dry-run HEAD~2` | Using it on commits that are published: branches are then "ahead N, behind M" | Each branch from its reflog (Lab 42.2); `git branch -r --contains <commit>` first | 14D.6 |
| `git replay` (experimental; Git 2.44) | 🟡 | Rebases or cherry-picks without a working tree and updates refs in one transaction (since 2.53) | `--onto=<commit> <range>`, `--advance=<branch> <range>`, `--revert=<branch>` (Git 2.54 or later), `--ref-action=print`; `--linearize` was added in Git 2.56 (not run here) | `git replay --ref-action=print --advance=main main..fix/timeout` | Expecting it to replay merge commits, or to stop for conflicts: it exits 1 without output | Rebase in a working tree | 14D.7 |
| `git format-patch` | 🟢 | Writes commits as patch files | `-1`, `--stdout`, `-o <dir>`, `--cover-letter`, `--base=<commit>`, `-v<n>`, `--range-diff=<previous>` | `git format-patch --cover-letter --base=origin/main -o ../outbox/v1 origin/main` | Omitting `--base`: the receiver cannot tell what the series applies to | Regenerate the files | 14D.11 |
| `git am` | 🟡 | Applies patch files as commits | `git am <files>`, `git am -3`, `--abort`, `--show-current-patch=diff` | `git am -3 ../outbox/v1/*.patch` | Applying to another base than the stated one: `patch does not apply` | `git am --abort`, then `git am -3` and resolve (Lab 42.3) | 14D.11 |
| `git apply` | 🟡 | Applies a diff to the working tree | `git apply <patch>`, `--check`, `--stat`, `-R`, `--index` | `git apply --check fix.patch` | Applying without `--check` | `git apply -R <patch>` | 14D.11, 28.18 |
| `git filter-repo`, `git filter-branch` | 🔴 | Rewrite every affected commit and all descendants on every rewritten ref. git-filter-repo is a separate program, not part of Git and not installed here; the chapter shows GitHub's documented sequence without output | `git-filter-repo --sensitive-data-removal --invert-paths --path <file>` (git-filter-repo 2.47 or later), in a fresh clone | `git-filter-repo --sensitive-data-removal --invert-paths --path PATH-TO-YOUR-FILE-WITH-SENSITIVE-DATA` | Rewriting the branches and forgetting the tags | The untouched server and other clones, until you push | 21B.17 |
| `git fast-export`, `git fast-import` | 🟢 | Move history between repositories of different object formats | `git fast-export --all \| git fast-import` | `git fast-export --all` | Expecting SHA-1 and SHA-256 repositories to exchange data directly | Delete the new repository | 14D.5 |
| `git replace` | 🟡 | Makes Git substitute one object for another when reading | `--graft <commit> <parent>`, `-d <object>` | `git replace --graft HEAD HEAD~2` | Forgetting a replace ref: a replacement object changes what the history is, so Git stops trusting the commit-graph file | `git replace -d <object>` | 26.6 |

### Signatures, trailers and small tools, all 🟢

| Command | Purpose | Forms taught | Example | Common mistake | Recover | Section |
|---|---|---|---|---|---|---|
| `git verify-commit`, `git verify-tag` | Check the signature of a commit or tag | `git verify-commit <commit>`, `--raw`; `git verify-tag <tag>`; `git tag -v <tag>`; `git log --show-signature`; `git log --format='%G? %GS'` | `git verify-commit HEAD` | SSH signatures without `gpg.ssh.allowedSignersFile`: a signed commit shows `No signature` | Create the allowed-signers file and configure it | 14B.16, 14B.17 |
| `git interpret-trailers` | Parses and adds trailers in a message | `--parse`, `--in-place <file>` | `git log -1 --format=%B \| git interpret-trailers --parse` | A trailer that is not in the last paragraph is not found | Move it; add trailers with `git commit --trailer` | 6.9 |
| `git merge-file` | Three-way merges three files | `git merge-file -p <ours> <base> <theirs>` | `git merge-file -p ours.yaml base.yaml theirs.yaml` | Reading a non-zero exit status as a failure: it is the number of conflicts | Not needed | 8.7 |
| `git archive` | Writes a tree as an archive, honouring `export-ignore` | `git archive --format=tar [--prefix=<dir>/] <commit>` | `git archive --format=tar --prefix=warehouse-api/ v1.1.0` | Expecting submodule content in the archive: it holds the entry and nothing below it | Fetch the submodules separately in the build | 14C.4, 23.12 |
| `git repo` (experimental, Git 2.52 or later) | Prints facts about the repository | `git repo info --all`, `git repo info --keys`, `git repo structure [--format=lines]` | `git repo info --all` | Scripts that depend on its output across versions | Pin the Git version | 14D.8 |
| `git check-ref-format` | Says whether a name is a valid ref name | `git check-ref-format <refname>`, `--branch <name>` | `git check-ref-format --branch fix/judge-timeout` | Creating `feature` when `feature/x` exists: the two cannot coexist as loose refs | `git branch -m` | 7.12 |

## 10. Plumbing

Plumbing commands have stable output for scripts and act on one part of the model at a time. The risk is in the writers that move refs or index entries without updating anything else.

| Command | Risk | Purpose | Forms taught | Example | Common mistake | Recover | Section |
|---|---|---|---|---|---|---|---|
| `git cat-file` | 🟢 | Reads an object: type, size, content | `-t <id>`, `-s <id>`, `-p <id>`, `-e <id>`, `-p <rev>:<path>`, `--batch-check[=<format>] --batch-all-objects` | `git cat-file -p HEAD^{tree}` | Assuming 40 hex digits: a SHA-256 repository has 64 | Not needed | 3.5 |
| `git hash-object` | 🟢 | Computes the ID of content; with `-w` stores it | `git hash-object <file>`, `-w <file>`, `--stdin`, `-t <type>` | `git hash-object -w config.toml` | Expecting the file name to affect the ID: names live in trees | Not needed | 2.4, 3.3 |
| `git ls-tree` | 🟢 | Lists a tree | `git ls-tree <tree-ish>`, `-r`, `--name-only`, `-t`, `-d`, `-l`, `--abbrev=<n>` | `git ls-tree -r --name-only HEAD` | Reading it for the staged state: it shows a commit's tree; the index is `git ls-files --stage` | Not needed | 3.5 |
| `git write-tree` | 🟢 | Writes the index as tree objects and prints the top ID | `git write-tree` | `git write-tree` | Expecting a commit: it writes trees and moves nothing | `git commit-tree`, then a ref | 2.6, 5.2 |
| `git commit-tree` | 🟢 | Writes one commit object and moves no ref | `git commit-tree <tree> [-p <parent>] -m <message>` | `git commit-tree 'main^{tree}' -p main -m 'Experiment that no ref points at'` | The commit is not in `git log`: nothing points at it | `git update-ref refs/heads/<branch> <id>`, or `git branch <name> <id>` | 2.6 |
| `git update-ref` | 🟡, 🔴 for `-d` | Writes or deletes one ref, with its reflog, and nothing else | `git update-ref <ref> <new> [<old>]`, `-m <reason>`, `-d <ref>`, `--stdin` | `git update-ref refs/backup/main <id>` | Moving the current branch with it: `git status` then shows changes that nobody made, because index and working tree did not follow. A short name creates a stray file | `git update-ref <ref> "<ref>@{1}"`; give full names that begin with `refs/` | 2.6, 3.9, 7.2 |
| `git symbolic-ref` | 🟢 to read, 🟡 to write | Reads or writes a symbolic ref such as HEAD | `git symbolic-ref HEAD`, `--short HEAD`, `git symbolic-ref HEAD <ref>`, `--delete <ref>` | `git symbolic-ref --short HEAD` | Expecting output in detached HEAD: it fails, because HEAD then holds an ID | `git rev-parse HEAD` | 3.9, 7.3 |
| `git update-index` | 🟡 | Writes index entries and flag bits directly | `--add --cacheinfo <mode>,<id>,<path>`, `--chmod=+x <path>`, `--refresh`, `-q --refresh`, `--assume-unchanged`, `--skip-worktree` and their `--no-` forms, `--index-version <n>`, `--show-index-version` | `git update-index --chmod=+x scripts/run.sh` | Using the two bits to "ignore" local edits to a tracked file | The `--no-` forms; `git ls-files -v` shows them | 2.6, 3.12, 5.12 |
| `git for-each-ref` | 🟢 | Lists refs in a format you choose | `--format=<format>`, `--sort=<key>`, `<pattern>`, `--include-root-refs`, `--exclude=<pattern>` | `git for-each-ref --format="%(objectname:short) %(objecttype) %(refname)"` | Parsing `git branch` output in scripts | Not needed | 2.8, 3.9, 7.13 |
| `git show-ref` | 🟢 | Lists refs with their IDs; tests existence | `--abbrev`, `--tags`, `--branches` (`--heads` is the deprecated synonym), `--dereference`, `--verify <ref>`, `--exists <ref>` | `git show-ref --exists refs/heads/main` | As above | Not needed | 3.9, 12.3 |
| `git pack-refs` | 🟢 | Moves loose refs into `packed-refs`; values are unchanged | `git pack-refs --all` | `git pack-refs --all` | Believing a ref is gone because its file is gone | `git rev-parse <ref>` | 3.9 |
| `git verify-pack`, `git show-index`, `git index-pack` | 🟢 | Read a pack and its index; rebuild a missing index | `git verify-pack -v <idx>`, `git show-index < <idx>`, `git index-pack <pack>` | `git verify-pack -v .git/objects/pack/pack-*.idx` | Deleting a pack because its `.idx` is missing | `git index-pack <pack>` (Lab 16.1) | 3.7 |
| `git unpack-objects`, `git pack-objects` | 🟢 | Explode a pack into loose objects; write a pack | `git unpack-objects -q < <pack>`, `git pack-objects --stdout` | `git pack-objects --stdout -q \| git unpack-objects -q` (IDs on standard input, 13.11) | Expecting it to replace a damaged object: it does not write objects that already exist in the repository | Move the damaged file out first, and keep it | 13.11 |
| `git diff-files`, `git diff-index` | 🟢 | The script forms of the index comparisons | `git diff-files [--name-status] [--quiet]`, `git diff-index --quiet HEAD` | `git diff-index --quiet HEAD` | A "dirty" answer in a fresh copy, because the cached stat data is stale | `git update-index -q --refresh` first | 5.14 |
| `git checkout-index` | 🟢 | Writes index entries as files | `git checkout-index --all --prefix=<dir>/` | `git checkout-index --all --prefix=../staged-snapshot/` | Omitting the trailing slash of the prefix | Delete the export | 5.5 |
| `git patch-id` | 🟢 | Computes an ID of a change that survives a rebase | `git patch-id --stable` | `git show <commit> \| git patch-id --stable` | Expecting equal patch IDs after a conflicted pick | Search for the `-x` line | 2.10, 10.10 |
