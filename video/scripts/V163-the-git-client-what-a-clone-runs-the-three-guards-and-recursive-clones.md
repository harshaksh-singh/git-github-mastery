# V163: The Git client: what a clone runs, the three guards, and recursive clones

- **Part.** 7: Security
- **Module.** 30
- **Planned minutes.** 22
- **Prerequisites.** V090, V091
- **Textbook sections.** [Chapter 21B](../../textbook/ch21b-repository-security-incident-response.md), sections 21B.2 to 21B.4
- **Demo scripts.** `labs/ch21b/client-safety.sh`

## HOOK

**[ON SCREEN]** Question 3 of section 21B.1: "An intern cloned a repository from a paper's footnote. What could that have run on the laptop?"

There are two versions of this story, and they have opposite answers. To clone is to make your own copy of a repository with Git.

In the first, the intern typed `git clone` with a URL. What Git ran on the laptop because of that: nothing the repository's author chose.

In the second, the footnote linked to a tarball, an archive file, called a "reproduction package", and the intern unpacked it and changed into the directory. The shell prompt showed the branch name, as shell prompts do. To show it, the prompt ran `git status`. And `git status` read a configuration file that the package's author wrote.

Same repository, same content, same intern. The difference is how the `.git` directory got onto the disk. Keep the second version in mind. You'll watch it happen, harmlessly, in the lab.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video opens Module 30, repository security, and it starts on your own machine. For two modules the question was what runs on a runner. Now the question is what runs on your laptop, with your SSH agent and your cloud credentials in reach.

**[ON SCREEN]** Lower third: Git.

Everything in this video is Git, not GitHub. Three topics, in the order of sections 21B.2 to 21B.4. What a clone copies and what it doesn't. The three standing guards that Git added in 2022: `safe.directory`, `safe.bareRepository` and `protocol.file.allow`. And the places where "cloning is safe" has had exceptions: recursive clones. Plus what hooks can and can't do as a control, and what stars prove.

The demonstration uses a repository prepared by "somebody else" that contains a hook and an alias. A hook is a file that Git runs at a defined point of a command, and an alias is a short name you define for a command. Both are harmless here: the hook appends a line to a log file, and the alias prints a sentence. They stand for what a hostile author could put there. Nothing hostile is shown.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- explain why cloning an untrusted repository is generally safe and unpacking an archive of one is not;
- explain "dubious ownership" and what `safe.directory` does and should not be set to;
- say what `safe.bareRepository=explicit` refuses and which attack it answers;
- explain `protocol.file.allow` and the risk of a recursive clone of an untrusted repository;
- say what stars and popularity do and do not prove.

## CONCEPT

**In one sentence.** Cloning a repository copies its objects and refs and nothing that Git would execute, so cloning and reading is generally safe. Running Git inside a `.git` directory that somebody else wrote isn't. Objects are the stored snapshots and files, and refs are the names, such as branches, that point at them.

**[ANIMATION]** stores: boxes=hooks:files_Git_runs|configuration:.git/config rows=1:A:the_files_in_.git/hooks|1:A:or_wherever_core.hooksPath_points|2:B:an_alias_beginning_with_an_exclamation_mark@hl|2:B:core.pager|2:B:core.editor|2:B:core.fsmonitor|2:B:core.sshCommand|2:B:a_credential_helper|2:B:a_filter_driver title=Two_kinds_of_file_under_.git_can_make_Git_execute_a_program id=files

**[ANIMATION]** step: files.boxes

**Precisely.** Two kinds of file under `.git` can make Git execute a program.

**[ANIMATION]** step: files.1

Hooks: the files in `.git/hooks`, or wherever `core.hooksPath` points.

**[ANIMATION]** step: files.2

And configuration: `.git/config`. An alias beginning with an exclamation mark names a shell command. So do `core.pager`, `core.editor`, `core.fsmonitor`, `core.sshCommand`, a credential helper, a filter driver, and several other settings.

**[ANIMATION]** say: Configuration_and_hooks_are_not_copied_by_git_clone

Git's manual states the rule in its SECURITY section. Configuration and hooks aren't copied by `git clone`. So cloning a remote repository with untrusted content and inspecting it with `git log` is generally safe. Running Git commands in a `.git` directory, or the working tree around it, that came from an untrusted source isn't. And the documented way to get a clean copy of such a directory is `git clone --no-local`.

**[ANIMATION]** stores: boxes=your_clone:git_clone|*source_repository:somebody_else's|"unpacked"_copy:cp_-R,_unzip,_tar_x rows=1:B:objects,_refs|1:B:.git/config|1:B:.git/hooks/*|2:A:objects,_refs@ok|2:A:config:_written_by_your_git_clone|2:A:hooks:_*.sample_only|3:C:objects,_refs|3:C:the_author's_config@bad|3:C:the_author's_hooks@bad arrows=2:B1>A1:pack_+_ref_advertisement|3:B1>C1:every_file_as_written|3:B2>C2|3:B3>C3 title=What_a_clone_copies,_and_what_an_archive_copies say_2=.git/config_and_.git/hooks:_not_copied say_3=With_an_archive,_all_three_cross id=copy

**[ANIMATION]** step: copy.2

**Inside `.git`.** A clone creates a new `.git` from the template directory of your own Git installation. Its hooks directory holds only the inactive sample files. Its `config` holds what `git clone` writes: the repository format, the `origin` remote and the branch's upstream. From the source it receives objects, in a pack, and refs. Nothing else crosses.

**[ANIMATION]** end

**The three guards.** Git added three standing defenses in 2022. Each closes one way of getting you to run Git inside configuration that you didn't write.

**[ANIMATION]** decide: nodes=q1:Owned_by_the_user_running_Git?|yes:Git_reads_its_configuration|q2:Listed_in_safe.directory?|ok:Git_reads_its_configuration|no:fatal:_detected_dubious_ownership edges=q1>yes:yes|q1>q2:no|q2>ok:yes|q2>no:no title=safe.directory:_whose_repository_directory_is_this? id=owner say_level_3=Honored_only_in_protected_configuration:_system,_global_and_command_scope

**[ANIMATION]** step: owner.level-2

**`safe.directory`. In one sentence:** Git refuses to read the configuration of a repository whose directory is owned by a different operating-system user, unless you have listed that directory as safe.

**[ANIMATION]** say: Git_walks_up_from_the_current_directory_to_find_a_repository

Why it exists: Git discovers a repository by walking up from the current directory. On a shared machine another user can create a `.git` directory high up, in a temporary or scratch directory. Without this check, any Git command you run below that directory would load their configuration and hooks.

**[ANIMATION]** step: owner.level-3

The check compares the owner of the repository directory with the user running Git. `safe.directory` lists exceptions. It is multi-valued. It accepts a path ending in a star for everything under a directory, and a lone star to switch the check off. And it's honored only in protected configuration: system, global and command scope. So a repository can't declare itself safe.

**[ON SCREEN]** Callout: Outdated advice. Answers from 2022 tell you to add a star to `safe.directory` in global configuration to make the message go away. That switches the protection off for every repository on the machine. List the one directory, or fix the ownership.

Outdated advice: answers from 2022 add a star to `safe.directory` in global configuration. That switches the protection off for every repository on the machine. List the one directory, or fix the ownership.

**`safe.bareRepository`. In one sentence:** with the value `explicit`, Git uses a bare repository only when you name it with `--git-dir` or `GIT_DIR`, never because you happened to be inside one.

**[ANIMATION]** stores: boxes=your_clone_of_a_project:ordinary_tracked_files|a_subdirectory_of_it:an_embedded_bare_repository rows=1:B:HEAD|1:B:objects|1:B:refs|1:B:config@bad|2:A:a_clone_does_copy_it@hl|3:B:with_explicit:_used_only_when_named_with_--git-dir_or_GIT__DIR@ok title=safe.bareRepository id=bare say_2=Change_into_it,_run_any_Git_command:_Git_reads_its_config at_1=5 at_2=70

**[ANIMATION]** step: bare.2

The attack it answers. A bare repository is a repository with no working tree: a directory with `HEAD`, `objects`, `refs` and `config`, and it doesn't need to be called `.git`. A project can therefore contain one as ordinary tracked files in a subdirectory. A clone does copy it, because to Git those are ordinary files. If you then change into that subdirectory and run any Git command, Git discovers the embedded bare repository and reads its `config`. So this is a way around the rule that a clone doesn't copy configuration.

**[ANIMATION]** step: bare.3

The default in Git 2.x is `all`. `explicit` will be the default in Git 3.0. The textbook's advice: if you don't work inside bare repositories by hand, set `explicit` globally now.

**[ANIMATION]** walk: columns=protocol,default_policy,meaning rows=the_safe_network_protocols:always:allowed|ext:never:refused|everything_else,_file_included:user:you_may_use_it_directly;_a_clone_Git_starts_on_its_own_may_not marks=3.2:hl mono=off title=protocol.file.allow id=proto

**[ANIMATION]** step: proto.header

**`protocol.file.allow`. In one sentence:** since 2022 the `file` transport defaults to the policy `user`: you may use it directly, and commands that start a clone on their own, such as submodule initialization, may not. A submodule is another repository checked out in a subdirectory of yours.

**[ANIMATION]** step: proto.3

The setting has three values: `always`, `never` and `user`. The safe network protocols default to `always`, `ext` to `never`, and everything else, `file` included, to `user`. The risk it closes: a `.gitmodules` file, the file that lists each submodule's path and URL, that names a local path makes a recursive clone read from a directory on your disk that the attacker chose.

**[ANIMATION]** end

**Recursive clones.** The textbook says the statement "cloning is safe" has had exceptions, and they share a shape: a repository with submodules, cloned with `--recurse-submodules`, tricks Git into writing a file where a hook is expected and then running it. Each has a CVE number, its entry in the public catalogue of vulnerabilities.

**[ON SCREEN]** The CVE table of section 21B.4.

CVE-2024-32002, critical, fixed in 2.45.1 and backports in May 2024: on a case-insensitive filesystem with symbolic links, a submodule could write a hook into `.git` that ran during the clone. The textbook notes that macOS meets those conditions: its default filesystem is case-insensitive and supports symbolic links.

CVE-2025-48384, high, fixed in 2.50.1 and backports in July 2025: a trailing carriage return in a submodule path checked content out to an unintended location where a hook could run.

CVE-2025-48385, fixed in 2.50.1 and backports: bundle URIs, which aren't enabled by default.

And CVE-2024-52005, with the default changed in core Git 2.55: unfiltered terminal escape sequences sent by a remote.

Where you stand: no core-Git advisory was published in 2026 up to the first of October. Your Git 2.55.0 contains every published core fix, and so does Apple's 2.50.1. And the advisory for the second CVE names the standing workaround, which is the rule to keep: don't recursively clone submodules of untrusted repositories.

**Hooks as a control.** The manual documents 28 hooks, six of which run on the receiving side of a push. Client-side hooks aren't cloned, and `pre-commit` and `commit-msg` are skipped by `--no-verify`. Since Git 2.54 hooks can also be declared in configuration, including global and system configuration, so the question "why did a hook run?" is now answered with `git hook list --show-scope` and the event name.

**[ANIMATION]** cards: question=A_pre-commit_hook_on_every_laptop._Is_that_a_control? cards=A:yes,_it_runs_before_every_commit|B:no,_the_committer_can_skip_it marks=1:bad,2:ok id=quiz

**[ANIMATION]** step: quiz.2

Quick quiz. A team wants to stop a certain kind of commit, and installs a `pre-commit` hook on every laptop. Is that a control? A, yes, it runs before every commit. B, no, the committer can skip it. Your answer?

**[PAUSE]**

**[ANIMATION]** step: quiz.marks

B. A client-side hook isn't a control, because the person it is meant to stop can skip it.

**[ANIMATION]** end

**Fake popularity.** For an engineer who clones research code weekly, the textbook says, the ecosystem is a larger risk than the client. Researchers documented a network of more than 3,000 GitHub accounts that distributed malware through repositories made to look popular. Hundreds of fake project repositories that stole about 5 bitcoin. And about six million suspected fake stars. Each figure is from the source cited in the section. The conclusion: stars, forks and a polished README aren't evidence of legitimacy.

## MENTAL MODEL

**Analogy,** from the textbook. A clone is a photocopy of a book: you get every page, and none of the previous owner's sticky notes that say "when you open this, also call this number". An unpacked archive that contains `.git` is the previous owner's own copy, sticky notes included, and Git follows them.

The analogy breaks in one place, and it matters for an ML engineer more than for most. The pages can still contain code that you later choose to run: a Makefile, a notebook. Git protects you from Git running something. It doesn't protect you from yourself running the project.

**[ANIMATION]** stores: boxes=Reading:Git_executes_nothing_the_author_chose|Git_acting_on_the_author's_own_metadata:Git_may_execute_or_be_steered_by_what_the_author_wrote|Running_the_project:the_author's_code,_by_your_decision rows=1:A:git_clone|1:A:git_log|1:A:git_show|1:A:git_diff|2:B:an_unpacked_.git@bad|2:B:an_embedded_bare_repository@bad|2:B:a_recursive_clone@bad|3:C:pip_install_-e_.|3:C:make|3:C:a_notebook's_first_cell title=Three_rings_of_trust,_from_inside_out id=rings

**[ANIMATION]** step: rings.boxes

So there are three rings of trust, from inside out.

**[ANIMATION]** step: rings.1

Reading: `git clone`, `git log`, `git show`, `git diff`. Git executes nothing the author chose.

**[ANIMATION]** step: rings.2

Git acting on the author's own metadata: an unpacked `.git`, an embedded bare repository, a recursive clone. Here Git may execute or be steered by what the author wrote.

**[ANIMATION]** step: rings.3

And running the project: `pip install -e .`, `make`, a notebook's first cell. That's the author's code, by your decision.

**[ANIMATION]** say: Clone,_do_not_unpack._Read_before_you_run

The four rules of the section follow from the rings. One: clone. Don't unpack somebody else's `.git`. If you must, `git clone --no-local` it first. Two: treat a recursive clone of an untrusted repository as running its code. Clone without submodules, read `.gitmodules`, then decide. Three: set `safe.bareRepository` to `explicit`, leave `protocol.file.allow` alone, and never set `safe.directory` to a star on a workstation. Four: cloning is the safe part. Read before you run, or run in a container without your credentials.

## DIAGRAM

Try it now, thirty seconds, on paper. Draw a source repository as a box with three lines: objects and refs, the config file, and the hooks. Draw one arrow labelled `git clone`, and a second labelled unzip. For each arrow, which of the three lines cross? Say it out loud.

**[PAUSE]**

**[ANIMATION]** stores: boxes=your_clone:git_clone|*source_repository:somebody_else's|"unpacked"_copy:cp_-R,_unzip,_tar_x rows=1:B:objects,_refs|1:B:.git/config|1:B:.git/hooks/*|2:A:objects,_refs@ok|2:A:config:_written_by_your_git_clone|2:A:hooks:_*.sample_only|3:C:objects,_refs|3:C:the_author's_config@bad|3:C:the_author's_hooks@bad arrows=2:B1>A1:pack_+_ref_advertisement|3:B1>C1:every_file_as_written|3:B2>C2|3:B3>C3 title=What_a_clone_copies,_and_what_an_archive_copies say_2=.git/config_and_.git/hooks:_not_copied say_3=With_an_archive,_all_three_cross id=copy2 at_2=10 at_3=45

**[ANIMATION]** step: copy2.1

**[DIAGRAM]** The picture of section 21B.2: two rows. Draw the top row first: source, arrow, clone, and write on the arrow what crosses and what does not. Then the bottom row with the same source and three arrows that all cross.

```text
  source repository                 git clone                    your clone
 +--------------------+                                     +---------------------+
 | objects, refs      | ---- pack + ref advertisement ----> | objects, refs       |
 | .git/config        |      (not copied)                   | config: written by  |
 | .git/hooks/*       |      (not copied)                   |   your git clone    |
 +--------------------+                                     | hooks: *.sample only|
                                                            +---------------------+

  source repository                 cp -R, unzip, tar x          "unpacked" copy
 +--------------------+                                     +---------------------+
 | objects, refs      | ---- every file as written -------> | objects, refs       |
 | .git/config        | ----------------------------------> | the author's config |
 | .git/hooks/*       | ----------------------------------> | the author's hooks  |
 +--------------------+                                     +---------------------+
```

**[ANIMATION]** step: copy2.3

Check your arrows. With a clone, one line crosses: objects and refs. Config and hooks stay behind. With an archive, all three cross. That's the whole difference between the two versions of the intern's story.

**[DIAGRAM]** The first line of both rows is the same. The second and third lines are the whole difference between the two versions of the intern's story.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch21b/client-safety`. Git, in the sandbox, with an isolated configuration; "global" below means the sandbox's global file, never yours.

**Step 1: what the author has.**

```bash
cat vendor-tool/.git/hooks/post-checkout
git -C vendor-tool config get alias.st
```

<!-- snippet: ch21b/client-safety/01-what-the-author-has -->
```text
$ cat vendor-tool/.git/hooks/post-checkout
#!/bin/sh
echo "post-checkout hook ran as $(basename "$PWD")" >> "$(git rev-parse --git-dir)/hook-ran.log"
$ git -C vendor-tool config get alias.st
!echo alias from the repository config ran
```
<!-- /snippet -->

A `post-checkout` hook that appends a line to a log file inside `.git`. And an alias, `st`, whose value begins with an exclamation mark: a shell command. Both harmless, both stand-ins.

**Step 2: clone it.**

```bash
git clone -q --no-local vendor-tool cloned
ls cloned/.git/hooks | grep -v '\.sample$' | wc -l
git -C cloned config get alias.st
git -C cloned switch -q -c try
```

`git clone --no-local` is 🟢 SAFE: it creates a new repository. `--no-local` forces the normal transport even for a path on the same disk, which is what the manual prescribes for untrusted sources. `git switch -c` is 🟢 SAFE: it adds a ref. In the clone: how many active hooks, is the alias defined, and does switching branches run the hook? Say it out loud.

**[PAUSE]**

<!-- snippet: ch21b/client-safety/02-clone-copies-neither -->
```text
$ git clone -q --no-local vendor-tool cloned
$ ls cloned/.git/hooks | grep -v '\.sample$' | wc -l
       0
$ git -C cloned config get alias.st
[exit status: 1]
$ git -C cloned switch -q -c try
$ ls cloned/.git | grep hook-ran || echo "no hook ran"
no hook ran
```
<!-- /snippet -->

Zero active hooks. The alias lookup exits with 1: not defined. And after a branch switch: "no hook ran".

**Step 3: receive the same repository as an archive.**

```bash
cp -R vendor-tool unpacked
cd unpacked
git st
git switch -q -c try
cat .git/hook-ran.log
```

`cp -R` stands for what unpacking a zip or a tarball that includes `.git` gives you: every file under `.git` arrives as written. Two Git commands. What does each run? Make your prediction.

**[PAUSE]**

<!-- snippet: ch21b/client-safety/03-unpacked-copy-runs-both -->
```text
# The same repository received as an archive: every file under .git arrives as written.
$ cp -R vendor-tool unpacked
$ cd unpacked
$ git st
alias from the repository config ran
$ git switch -q -c try
$ cat .git/hook-ran.log
post-checkout hook ran as unpacked
$ cd ..
```
<!-- /snippet -->

`git st` printed the author's sentence: it ran the author's shell command. `git switch` ran the author's hook, and the log file proves it. That's the intern's second story, with a harmless sentence in place of a program. With a hostile archive those would have been any program, running as you.

**Step 4: dubious ownership.**

```bash
GIT_TEST_ASSUME_DIFFERENT_OWNER=1 git -C unpacked status -sb
```

The sandbox can't change file ownership without `sudo`, so the transcript uses the variable that Git's own test suite uses to simulate a foreign owner. The real message appears in containers and CI, where the checkout is often owned by another user ID.

<!-- snippet: ch21b/client-safety/04-dubious-ownership -->
```text
# GIT_TEST_ASSUME_DIFFERENT_OWNER=1 makes Git treat the repository as owned by another user.
$ GIT_TEST_ASSUME_DIFFERENT_OWNER=1 git -C unpacked status -sb
fatal: detected dubious ownership in repository at '$LAB/ch21b/client-safety/unpacked'
To add an exception for this directory, call:

	git config --global --add safe.directory $LAB/ch21b/client-safety/unpacked
[exit status: 128]
```
<!-- /snippet -->

"Detected dubious ownership", exit status 128, and Git prints the command for an exception for this one directory.

```bash
git config set --global --append safe.directory "$PWD/unpacked"
git config unset --global safe.directory
git -C unpacked config set safe.directory '*'
```

`git config set --global --append safe.directory` is 🟡 CAUTION: it makes Git trust that directory's configuration and hooks. The preview is to read that directory's `.git/config` and hooks first. After the exception is removed from global configuration, a star is written into the repository's own configuration. Does Git accept the repository then? Say it out loud.

**[PAUSE]**

<!-- snippet: ch21b/client-safety/05-safe-directory -->
```text
$ git config set --global --append safe.directory "$PWD/unpacked"
$ GIT_TEST_ASSUME_DIFFERENT_OWNER=1 git -C unpacked status -sb
## try
[exit status: 0]
# The setting is honoured only in protected configuration. In the repository itself it is ignored:
$ git config unset --global safe.directory
$ git -C unpacked config set safe.directory '*'
$ GIT_TEST_ASSUME_DIFFERENT_OWNER=1 git -C unpacked status -sb 2>&1 | head -1
fatal: detected dubious ownership in repository at '$LAB/ch21b/client-safety/unpacked'
```
<!-- /snippet -->

With the exception in global configuration, status works. With a star in the repository's own configuration: dubious ownership again. The textbook calls the last three lines the important ones. That file is exactly what Git declined to trust, so writing "trust me" into it changes nothing. Almost everyone expects it to work the first time.

**Step 5: an embedded bare repository.**

```bash
git -C embedded.git log --oneline
git config set --global safe.bareRepository explicit
git -C embedded.git log --oneline
git --git-dir=embedded.git log --oneline
```

`git config set --global safe.bareRepository explicit` is 🟡 CAUTION: global configuration keeps no history, and the setting changes how later commands treat bare repositories.

<!-- snippet: ch21b/client-safety/06-bare-repository -->
```text
$ git -C embedded.git log --oneline
418a3a1 Add tool
$ git config set --global safe.bareRepository explicit
$ git -C embedded.git log --oneline
fatal: cannot use bare repository '$LAB/ch21b/client-safety/embedded.git' (safe.bareRepository is 'explicit')
[exit status: 128]
$ git --git-dir=embedded.git log --oneline
418a3a1 Add tool
$ git config unset --global safe.bareRepository
```
<!-- /snippet -->

By default, changing into the bare repository is enough for Git to use it. With `explicit`, Git refuses: "cannot use bare repository". Naming it with `--git-dir` works. The script unsets the value again, because the labs inspect the bare "server" with `git -C`.

**Step 6: a clone you did not ask for.**

```bash
git submodule add ../vendor-tool vendor/tool
git config get protocol.file.allow
git -c protocol.file.allow=always submodule add -q ../vendor-tool vendor/tool
```

A submodule whose URL is a local path. The setting isn't configured at all. What happens? Make your prediction.

**[PAUSE]**

<!-- snippet: ch21b/client-safety/07-file-protocol -->
```text
$ cd app
$ git submodule add ../vendor-tool vendor/tool
Cloning into '$LAB/ch21b/client-safety/app/vendor/tool'...
fatal: transport 'file' not allowed
fatal: clone of '$LAB/ch21b/client-safety/vendor-tool' into submodule path '$LAB/ch21b/client-safety/app/vendor/tool' failed
[exit status: 128]
$ git config get protocol.file.allow
[exit status: 1]
$ git -c protocol.file.allow=always submodule add -q ../vendor-tool vendor/tool
$ git submodule status | cut -c1-9,42-
 418a3a1f vendor/tool (heads/main)
```
<!-- /snippet -->

"Transport 'file' not allowed." The default policy let you use the file transport yourself and refused it to a clone that Git started on its own. The one-off `-c` on the command line is correct for a local experiment such as this one. Setting it globally removes the guard. Leave the default.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Unpacking an archive that contains `.git` and working in it.** Root cause: every file under `.git` arrives as written, including the author's configuration and hooks, and Git follows them.
2. **Setting `safe.directory` to a star.** Root cause: that switches the ownership check off for every repository on the machine; list the one directory or fix the ownership.
3. **Cloning an untrusted repository with `--recurse-submodules`.** Root cause: the published exceptions to "cloning is safe" share that shape; the standing workaround is not to do it.
4. **Relying on a client-side hook as a control.** Root cause: hooks are not cloned, and the person they are meant to stop can skip them with `--no-verify`.
5. **Trusting a repository because it has many stars.** Root cause: stars, forks and a polished README can be manufactured and are not evidence of legitimacy.

## PRODUCTION EXAMPLE

Now, out of the lab. The textbook's case. An ML team receives a "reproduction package" for a paper as a tarball that contains a full repository. A shell prompt that shows the branch name runs `git status` as soon as someone changes into the directory. And `git status` consults `core.fsmonitor` from the package's own `.git/config`.

Nobody typed a Git command. Nobody ran the project. Changing directory was enough.

**[ANIMATION]** replay: rings

The safe procedure is the manual's: `git clone --no-local package clean`, and work in `clean`. The clone takes the objects and the refs, and leaves the author's configuration and hooks behind. After that the team is in the first ring: reading. Whether to enter the third ring and run the paper's code is a separate decision, made after reading, or made inside a container without credentials.

## PRACTICE EXERCISE

Your turn. Do Exercise 30.1, "What could that have run?", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

For each situation in the exercise, before you answer, say which of the three rings it is in: reading, Git acting on the author's metadata, or running the project. Predict for each which file, if any, could cause a program to start.

The challenge is Exercise 30.7, "The reproduction package", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q308: "Explain why `git clone` of an untrusted repository is generally safe and why unpacking a tarball of the same repository is not. Name the files involved."

Read the question on screen. Say your answer out loud.

**[PAUSE]**

A strong answer names the two kinds of file under `.git` that can make Git start a program, with examples of each, and says what a clone creates in their place and from where. It then describes what an unpacked copy contains and gives one ordinary command that would trigger each kind. It names the documented way to get a clean copy. The follow-up says that "cloning is safe" has had exceptions and asks what shape they share and what standing rule follows. You have the table and the workaround.

## RECAP

Let's land this.

You should now be able to say:

- A clone copies objects and refs; hooks and configuration are not copied, so cloning and reading is generally safe.
- An unpacked `.git` brings the author's configuration and hooks; get a clean copy with `git clone --no-local`.
- `safe.directory` is the exception list for repositories owned by another user, honored only in protected configuration, and never to be set to a star on a workstation.
- `safe.bareRepository=explicit` refuses bare repositories that were not named explicitly, and `protocol.file.allow` keeps Git from starting file-transport clones on its own.
- A recursive clone of an untrusted repository is to be treated as running its code, and popularity proves nothing.

## HOMEWORK

Read sections 21B.2 to 21B.4 of [Chapter 21B](../../textbook/ch21b-repository-security-incident-response.md).

Today you watched the same repository arrive twice, as a clone and as an archive, and you know which one runs the author's files. Replay that demo in the lab shell. Next time: credentials, and what a stolen one can reach. Until then, look at the state first and type second. See you in the next one.
