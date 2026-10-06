# Module 5 lab answers: Configuration, identity, and a professional setup

Answers to the Questions in [lab-manual/m05-configuration.md](../lab-manual/m05-configuration.md). Read them after you have written your own. Paths and IDs quoted here are the ones printed by the replay scripts; where your own run produced others, the reasoning is the same.

## Lab 5.1: Scopes and origins

1. **The last line.** `--all` prints the values in the order Git reads them: system, global, local, worktree, command. For a single-valued key the value read last is the one every command uses, so with `true` from the global file and `false` from the local file, `pull.rebase` is `false`. Nothing is merged or compared; a later value replaces an earlier one.

2. **`pull.ff=only` was in force; `pull.rebase=interactive` was not.** Precedence is decided per key. `pull.ff` was set in the stand-in system file and nowhere else, so its value reached every command. `pull.rebase` was also set in the global file (`true`) and in the local file (`false`), both of which are read after the system file, so `false` won. A system file can therefore set defaults that hold exactly until a user or a repository sets the same key, which is what an administrator's file is for. Without the two environment variables the stand-in file is not read at all, as in every other step of the lab.

3. **Because `GIT_AUTHOR_NAME` is not part of the configuration.** `-c` is the last *configuration* scope, and it did set `user.name` to "Day Shift". But when Git builds the author identity it asks the environment first: the manual says that `GIT_AUTHOR_NAME` "overrides the `user.name` and `author.name` configuration settings". Configuration scopes compete with each other; an environment variable that Git consults before the configuration does not take part in that competition. `git var GIT_AUTHOR_IDENT` shows the result of both.

4. **Into `.git/config`, silently.** Without `extensions.worktreeConfig`, `--worktree` behaves like `--local`; the manual says so, and the chapter's `scopes` demo shows it. You would notice with `git config get --show-scope --show-origin core.sparseCheckout`: the scope column says `local` and the origin is `.git/config`, where you expected `worktree` and `.git/config.worktree`. The habit that catches it is to read a value back with its origin after writing it.

5. **Because every Git command that runs inside a repository loads that repository's configuration first**, whatever the command is about. `git config list --global` restricts what is *printed* to one scope; the startup still parses `.git/config`, and the parse error is fatal before the listing begins. Any directory outside the broken repository works, for example the sandbox's home (`cd ~`): there is no local file to read.

## Lab 5.2: Two identities with `includeIf`

1. **Two, because two files were read in that scope and both set the key.** The global file sets `user.email = you@example.com` in its `[user]` section. Further down, the `includeIf` section matched, and Git read `~/.gitconfig-work` at that point, as if its lines stood there; a file included from a global file belongs to the global scope. The second value was read later, so it wins. The origin column tells the two lines apart: `.gitconfig` and `.gitconfig-work`.

2. **The shell would have expanded `$HOME` before Git saw it**, so the stored section would be `[includeIf "gitdir:/…/home/work/"]` with an absolute path. It works on this machine. It is worse in two ways: the file is no longer portable (a dotfiles repository shared between a laptop and a server with different home directories), and it hides the intent. With `~/` in the pattern, Git substitutes the value of `HOME` each time it reads the file.

3. **The personal address.** The included file would be read first, then the `[user]` section of the including file, whose `email` would be the value read last. `git config get --all --show-origin user.email` shows it directly: the work value on the first line, the personal value on the second, and the last line wins. The remedy is to keep conditional includes at the end of the file. The chapter's `includes` demo runs exactly this case.

4. **Inside the new repository: the work address.** `git init` created `~/work/new-service/.git`, which is under `~/work/`, so the condition is true from the first command on. **In `~/work` itself: the personal address.** `gitdir` is a condition on the location of a repository's `.git` directory, and in a directory that is not inside a repository there is none, so the condition cannot be true.

5. **Leave them, in almost every case.** They are part of a history that may be published; changing an author line means rewriting those commits and every descendant, with new IDs for all of them and a forced push that every other clone has to follow (Chapters 6, 9 and 12). Rewrite only if the commits are unpublished, or if the address itself must not be public and the team accepts the cost of a coordinated history rewrite (Chapter 21B). A wrong address in old commits is normally a matter for a `.mailmap` file, which changes how names are displayed without changing history.

## Lab 5.3: Aliases

1. `git log --graph --decorate --oneline --all -2 main`. Everything up to `--all` is the alias; `-2 main` is what you typed. Git replaced the word `lg` by the alias value and appended the remaining arguments unchanged.

2. **Because the alias turned your command into `git log -1 --stat HEAD --format=... feature/fallback-route`.** `git log A B` walks the commits reachable from A *or* B, newest first, and `-1` stops after the first one. The newest commit reachable from `HEAD` or the feature branch was the tip of `main`. With `HEAD` removed from the alias, the only starting point is the one you name, and when you name none, `git log` uses HEAD by default.

3. **A file whose name begins with a dash**, for example a file called `-q`. `git restore --staged -q` reads `-q` as the option "quiet" and then fails with "you must specify path(s) to restore". `git restore --staged -- -q` unstages the file. `--` ends option parsing; everything after it is a path.

4. **The reflog.** `git reflog -2` showed `HEAD@{0}: commit (amend)` and below it `HEAD@{1}: commit`, the old commit `1adfaa7`. The entry is a line in `.git/logs/HEAD` (and in `.git/logs/refs/heads/main`). `git reset --soft 'HEAD@{1}'` moves the branch back to it and keeps your index; `git branch rescue 'HEAD@{1}'` gives it a name without moving anything.

5. **Nothing changes: the alias is ignored.** Git looks for a real command first, and an alias cannot hide one. That is the right behavior because every script, hook and tool that runs `git log` depends on its documented output; if a user's alias could redefine it, no script would be portable between two machines. To change your default format, use the settings made for it (`format.pretty`, `log.abbrevCommit`) or an alias with another name.

## Lab 5.4: Your deliberate configuration

1. **Standardize what the repository or the server depends on; leave alone what only changes one person's view or habits.** In practice the first group is small: the default branch name the team uses, identity rules (`user.useConfigOnly`, the work address for work repositories), whatever signing the server enforces, and line-ending handling, which belongs in `.gitattributes` in the repository and not in anyone's configuration. Diff algorithms, conflict styles, aliases, editors, `rerere`, autosquash and pull strategy for one's own branches are personal: they do not change what gets pushed. A setup script should also say why each line is there, or it will be cargo within a year.

2. **A branch you did not mean to publish yet, or under a name you did not mean.** Without the setting, the first `git push` of a new branch stops and makes you type the remote and the branch name, which is a moment of review. With it, a branch created with a typo in its name, a branch holding work-in-progress commits, or a branch created from the wrong base is on the server one word later, visible to everyone and to every CI trigger that reacts to new branches.

3. **It still refuses.** With `pull.ff=only` and `pull.rebase=true` both in configuration, a diverged `git pull` stops with "fatal: Not possible to fast-forward, aborting." Chapter 12, section 12.6, ran all combinations: in configuration, `pull.ff=only` wins over `pull.rebase`, and a flag on the command line beats both. So the practical effect of this pair is "refuse by default, and I say `git pull --rebase` when I mean it". Confirm it in the sandbox: `main` in `you/inference-gateway` is still `[ahead 1, behind 1]`, so run `git pull` and then `git pull --rebase`.

4. **Because Git's configuration files are shared with programs and versions that Git does not know.** The manual says it plainly: other Git-related tools "may and do use their own variables". A credential helper, Git LFS, an editor integration or a newer Git all store keys that this binary has never heard of, and a configuration written by Git 2.56 must still load in Git 2.55. If unknown keys were an error, every such key would break every command. The price is that typing mistakes are silent, which is why a check like the one in the lab is worth having.

5. **`user.email` is the obvious one**, through a conditional include or directly in `.git/config`, when one machine serves two contexts. Others with good reasons: `commit.gpgSign` in a repository whose server requires signatures; `core.sshCommand` in a repository that must use a specific key; `pull.rebase` in a repository whose team has agreed on a history shape that differs from your default. The principle: a setting is global when it describes *you*, and local when it describes *this project*.
