# V101: Turning names into IDs: git rev-parse

- **Part.** 4: Git internals
- **Module.** 17
- **Planned minutes.** 14
- **Prerequisites.** V064, V100
- **Textbook sections.** [Chapter 3](../../textbook/ch03-git-internals.md), section 3.6 (and [Chapter 2](../../textbook/ch02-mental-model.md) for the rule about abbreviated IDs)
- **Demo scripts.** `labs/ch03/rev-parse.sh`

## HOOK

**[ON SCREEN]** A deploy record: the field "commit" contains the text `no-such-branch`.

A deploy script is supposed to record the commit ID it deployed, the fingerprint of one exact snapshot. One morning the record holds the text "no-such-branch" where forty hexadecimal digits should be. The script didn't fail. It didn't warn. It carried a branch name that doesn't exist all the way into the deploy record.

Your CTO asks: how can a tool ask Git for a commit and get back a word? The answer is in how `git rev-parse` behaves when it can't resolve a name, and it's a one-flag fix. Hold on to that word. It comes back.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Every Git command that takes a revision, `git log main`, `git show HEAD~2`, `git diff v1.0.0`, turns that argument into an object ID first. A revision is any expression that names an object. The resolver behind all of them is one command, `git rev-parse`. Today you use it directly, for two jobs: turning names into IDs, and asking a repository questions about itself.

`git rev-parse` only reads. It is 🟢 SAFE: it changes nothing.

**[ANIMATION]** graph: b602c1f-4f2cc0c-0c2cf43 main atag:v1.0.0#0b624ed; ^b602c1f-62001eb feature/batching; 62001eb-0c2cf43; 4f2cc0c tag:v1.0.0-rc1; HEAD=main title=The_demo_repository id=repo

We replay `labs/ch03/rev-parse.sh`, on the same inference-service repository as the previous video, so you'll recognize the IDs. Here it is: four commits, with the branch `main` and the tag `v1.0.0` on the merge.

## LEARNING OBJECTIVES

After this video you can:

- Resolve any revision expression to an object ID and verify that it names a commit.
- Ask a repository for its directory, its top level and its formats from a script.
- Explain the order in which Git resolves an ambiguous short name.
- Say why a tool should store full IDs and not abbreviations.

## CONCEPT

Why does this command matter? Because scripts that guess are the scripts that break. A script that assumes where `.git` is, or that a name is a branch, or that a captured string is an ID, works until the day the assumption is false. `git rev-parse` replaces each guess with a question to Git.

**[ANIMATION]** step: repo.state-1

**[ANIMATION]** say: Any_name_goes_in,_one_object_ID_comes_out

In one sentence: `git rev-parse` resolves anything that can name an object to its object ID and answers questions about the repository itself, by the same rules that every other Git command applies to its arguments.

**[ANIMATION]** end

**[ON SCREEN]** The revision table of section 3.6.

The revision syntax, with the values from the demo repository. A ref is a name that holds an object ID, and a ref name such as `main`, `v1.0.0` or `HEAD` means the object the ref names. For an annotated tag, that's the tag object. `HEAD~2` means two steps back, following first parents only. `HEAD^2` means the second parent of a merge. `HEAD^1`, or `HEAD^` alone, is the first. `HEAD^{tree}` means the object of that type reached by following the name: here, the commit's tree. `v1.0.0^{commit}` peels the tag to a commit, and `v1.0.0^{}` peels until it's no longer a tag. `HEAD:src/server.py` is the blob or tree at that path in that commit. A leading colon, as in `:config.toml`, reads the entry for that path in the index, the staging area, and `:2:config.toml` reads the entry at stage 2. And `main@{1}` is the previous value of the ref, read from its reflog, the ref's local journal.

**[ANIMATION]** match: header=a_short_name_is_tried_as rules=$GIT__DIR/<name>:first|refs/<name>:then|refs/tags/<name>:tags|refs/heads/<name>:branches|refs/remotes/<name>:then|refs/remotes/<name>/HEAD:last paths=main:3+4 wins=first title=The_lookup_order_of_a_short_name id=order

Now the internals of name lookup. A bare name is looked up in a fixed order: first `$GIT_DIR/<name>`, then `refs/<name>`, then `refs/tags/<name>`, then `refs/heads/<name>`, then `refs/remotes/<name>`, and last `refs/remotes/<name>/HEAD`. Tags come before branches in that list. A tag therefore wins over a branch of the same name. Git 2.55 prints `warning: refname 'main' is ambiguous.` and uses the tag. In scripts, write the full name, `refs/heads/main`.

**[ANIMATION]** end

The second family of options describes the repository: `--git-dir`, `--show-toplevel`, `--show-prefix`, `--show-cdup`, `--is-inside-work-tree`, `--is-bare-repository`, `--show-object-format`, `--show-ref-format` and `--git-path`. These are what a script uses in place of assumptions about paths.

When should you not rely on it without care? Without `--verify`, the command is a sorter of arguments, not a validator. That's the failure mode of the hook, and we'll see it on screen.

## MENTAL MODEL

**[ANIMATION]** step: repo.state-1

**[ANIMATION]** say: The_front_desk:_a_name_in_any_form_goes_in,_one_object_ID_comes_out

Think of `git rev-parse` as the front desk that every other Git command passes through. You hand over a name in any of the forms Git understands, and the desk hands back the one thing that is unambiguous: an object ID.

**[ANIMATION]** end

The model breaks in one place. A front desk refuses a visitor it can't identify. `git rev-parse` without `--verify` doesn't refuse: its first purpose is to sort the arguments of a calling script into revisions and everything else, so what isn't a revision is passed through. You have to ask for the strict behaviour.

One more rule belongs to the model, and it comes from Chapter 2: names can be ambiguous, full object IDs cannot. An abbreviation is unique only in one repository at one time. An abbreviated ID in a script or a ticket can become ambiguous as the repository grows. Store full IDs.

## DIAGRAM

**[ANIMATION]** graph: b602c1f-4f2cc0c-0c2cf43 main atag:v1.0.0#0b624ed; ^b602c1f-62001eb feature/batching; 62001eb-0c2cf43; 4f2cc0c tag:v1.0.0-rc1; HEAD=main => + 4f2cc0c special:HEAD^1 special:HEAD~1; 62001eb special:HEAD^2; name:parents; say:^_chooses_a_parent:_HEAD^1_is_the_first,_HEAD^2_the_second => + b602c1f special:HEAD~2 special:HEAD^1^1; name:generations; say:~_counts_generations,_^_chooses_a_parent id=rev title=Naming_commits_from_HEAD

**[ANIMATION]** step: state-1

**[DIAGRAM]** Draw the graph first, then add the labels on the right.

```text
                62001eb   feature/batching                   HEAD^2
               /       \
   b602c1f ---+         +--- 0c2cf43   main, tag v1.0.0   (HEAD -> main)
               \       /
                4f2cc0c   tag v1.0.0-rc1                     HEAD^1 = HEAD~1

   HEAD~2 = HEAD^1^1 = b602c1f                  ~ counts generations, ^ chooses a parent
```

The root commit `b602c1f` is on the left. Two commits follow it: `4f2cc0c` on the lower line and `62001eb` on the upper line, the branch `feature/batching`. They meet in the merge `0c2cf43`, where `main`, the tag `v1.0.0` and HEAD are.

**[ANIMATION]** step: parents

Now the labels. `HEAD^1` is the first parent, the lower line, and it's the same commit as `HEAD~1`. `HEAD^2` is the second parent, the upper line.

**[ANIMATION]** step: generations

`HEAD~2` is two generations back along first parents, which is `HEAD^1^1`, the root. Say the rule out loud: tilde counts generations, caret chooses a parent.

**[PAUSE]**

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch03/rev-parse
```

**[ANIMATION]** step: repo.state-1

Predict, then look. I'm about to ask for `HEAD~2`, `HEAD^2` and `HEAD^1`, in that order. Point at each commit on the graph and say its ID. I'll wait.

**[PAUSE]**

**[ANIMATION]** end

Quick quiz: `v1.0.0`, then `v1.0.0` peeled to a commit. One ID twice, or two different IDs? Your answer?

**[PAUSE]**

```bash
git log --graph --oneline
git rev-parse HEAD
git rev-parse --short HEAD
git rev-parse HEAD~2 HEAD^2 HEAD^1
git rev-parse "HEAD^{tree}" HEAD:src HEAD:src/server.py
git rev-parse v1.0.0 "v1.0.0^{commit}"
```

<!-- snippet: ch03/rev-parse/01-revisions -->
```text
$ git log --graph --oneline
*   0c2cf43 Merge feature/batching
|\  
| * 62001eb Add batch size setting
* | 4f2cc0c Add readiness handler
|/  
* b602c1f Add inference service skeleton
$ git rev-parse HEAD
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
$ git rev-parse --short HEAD
0c2cf43
# ~2 follows first parents twice. ^2 is the second parent of a merge. ^1 is the first.
$ git rev-parse HEAD~2 HEAD^2 HEAD^1
b602c1fa61adb577fc9ca3113292b7cf734e856a
62001eb879c6506f6d3c8e625dfadfa5029367b7
4f2cc0c5f842120f109977a97bc72acef5aa5ccd
# From a commit to its tree, to a subtree, to a blob:
$ git rev-parse "HEAD^{tree}" HEAD:src HEAD:src/server.py
31fc0d39799d6931bb12f7befeb250a539f84a96
c009bc4782e140b36dc7a2136770393623a345bf
e2238784c412f0a5151764c07c7a44e7b3a9c073
# A tag object, and the commit it peels to:
$ git rev-parse v1.0.0 "v1.0.0^{commit}"
0b624edf4a556c702b6ed110ef2702570ced1558
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
```
<!-- /snippet -->

`HEAD~2` is the root, `HEAD^2` is the commit of the feature branch, `HEAD^1` is the commit on the first-parent line. The last command prints two different IDs: the tag object first, then the commit it peels to, which is HEAD. If you said one ID twice, you're in good company.

The other direction: from HEAD or a short name to a full ref name.

```bash
git rev-parse --abbrev-ref HEAD
git rev-parse --symbolic-full-name HEAD
git rev-parse --symbolic-full-name v1.0.0 feature/batching
git rev-parse "main@{1}"
git rev-parse :config.toml
```

<!-- snippet: ch03/rev-parse/02-names -->
```text
$ git rev-parse --abbrev-ref HEAD
main
$ git rev-parse --symbolic-full-name HEAD
refs/heads/main
$ git rev-parse --symbolic-full-name v1.0.0 feature/batching
refs/tags/v1.0.0
refs/heads/feature/batching
# The previous value of a branch comes from its reflog:
$ git rev-parse "main@{1}"
4f2cc0c5f842120f109977a97bc72acef5aa5ccd
# A leading colon reads the index, not a commit:
$ git rev-parse :config.toml
60a72d9888260645df622ecd424e474d09d40560
```
<!-- /snippet -->

`--abbrev-ref` prints the short branch name. `--symbolic-full-name` prints the full ref, and shows you which namespace a short name was found in. `main@{1}` comes from the reflog. The last line reads the index, not a commit.

Try it now, thirty seconds, in a repository in the lab shell: `git rev-parse --abbrev-ref HEAD`, then `git rev-parse HEAD`. I'll wait.

**[PAUSE]**

A short branch name first, then a full commit ID.

Questions about the repository.

```bash
git rev-parse --git-dir --show-toplevel
cd src/handlers
git rev-parse --git-dir
git rev-parse --show-prefix --show-cdup
git rev-parse --is-inside-work-tree --is-bare-repository
git rev-parse --show-object-format --show-ref-format
git rev-parse --git-path hooks/pre-commit
cd ../..
```

At the top level, `--git-dir` prints `.git`. What will it print from two directories down? Say it out loud.

**[PAUSE]**

<!-- snippet: ch03/rev-parse/03-repository -->
```text
$ git rev-parse --git-dir --show-toplevel
.git
$LAB/ch03/rev-parse/inference-service
$ cd src/handlers
$ git rev-parse --git-dir
$LAB/ch03/rev-parse/inference-service/.git
$ git rev-parse --show-prefix --show-cdup
src/handlers/
../../
$ git rev-parse --is-inside-work-tree --is-bare-repository
true
false
$ git rev-parse --show-object-format --show-ref-format
sha1
files
$ git rev-parse --git-path hooks/pre-commit
../../.git/hooks/pre-commit
$ cd ../..
```
<!-- /snippet -->

`--git-dir` answers relative to where you are. `--show-prefix` and `--show-cdup` are the path from the top level down to the current directory and back up. `--show-object-format` and `--show-ref-format` name the two storage formats that later videos of this part cover. `--git-path` gives the location of a file inside the repository, and stays right when the repository is a linked worktree or an environment variable relocates part of it.

Now the hook. Error handling is where scripts go wrong.

```bash
id=$(git rev-parse no-such-branch 2>/dev/null); echo "status=$? captured=[$id]"
id=$(git rev-parse --verify --quiet no-such-branch); echo "status=$? captured=[$id]"
git rev-parse --verify no-such-branch
git rev-parse --verify --quiet "v1.0.0^{commit}"
git rev-parse --short HEAD~2 HEAD^2
git rev-parse --verify "HEAD^3"
```

The first line asks for a branch that doesn't exist and hides the error stream. What ends up in the variable: nothing, an error message, or the name itself? Your answer?

**[PAUSE]**

<!-- snippet: ch03/rev-parse/04-errors -->
```text
# Without --verify, rev-parse prints what it cannot resolve on standard output:
$ id=$(git rev-parse no-such-branch 2>/dev/null); echo "status=$? captured=[$id]"
status=128 captured=[no-such-branch]
# With --verify it prints one object ID or nothing, and --quiet drops the message:
$ id=$(git rev-parse --verify --quiet no-such-branch); echo "status=$? captured=[$id]"
status=1 captured=[]
$ git rev-parse --verify no-such-branch
fatal: Needed a single revision
[exit status: 128]
$ git rev-parse --verify --quiet "v1.0.0^{commit}"
0c2cf4371cac2e5d412153dc58293c0cb484c4ba
[exit status: 0]
# --short implies --verify, so it accepts exactly one revision:
$ git rev-parse --short HEAD~2 HEAD^2
fatal: Needed a single revision
[exit status: 128]
# A merge with two parents has no third parent:
$ git rev-parse --verify "HEAD^3"
fatal: Needed a single revision
[exit status: 128]
```
<!-- /snippet -->

The variable holds the text `no-such-branch`, and the status is 128. That's the word in the deploy record, explained. With `--verify --quiet`, the variable is empty and the status is 1. `--short` implies `--verify`, so it accepts exactly one revision. And a merge with two parents has no third parent.

**[ON SCREEN]** The root-cause box of section 3.6, one line at a time.

```text
Observed behavior : a deploy script stores the text "no-such-branch" in a variable that should hold a commit ID
Git state         : the name resolves to nothing
Mechanism         : without --verify, git rev-parse prints an argument it cannot resolve on standard output,
                    writes the error to standard error, and exits with status 128
Root cause        : the script captured standard output and never looked at the exit status
Why Git does this : the first purpose of rev-parse is to sort the arguments of a calling script into
                    revisions and everything else, so what is not a revision is passed through
Correct fix       : id=$(git rev-parse --verify --quiet "$name^{commit}") || exit 1
Prevention        : use --verify in every script; add ^{commit} when the object must exist and be a commit
```

**[ANIMATION]** walk: columns=the_script_runs,what_is_checked rows=git_rev-parse_<name>:nothing:_an_unresolved_name_is_printed_back|git_rev-parse_--verify_<name>:the_argument_can_be_turned_into_an_ID|git_rev-parse_--verify_<name>^{commit}:the_object_exists_and_is_a_commit marks=1.2:bad,2.2:wait,3.2:ok title=What_each_form_checks id=verify

One limit of `--verify`: it accepts exactly one argument and prints one ID or nothing. It checks that the argument can be turned into an ID, not that the object is in the database. A full forty-digit ID passes even if no such object exists. The peeling suffix closes that gap, because `^{commit}` has to read the object.

## COMMON MISTAKES

Five mistakes to watch for.

1. Capturing the output of `git rev-parse` without `--verify`. Root cause: an unresolvable argument is printed on standard output and only the exit status reports the failure.
2. Trusting `--verify` to prove an object exists. Root cause: it checks that the argument can be turned into an ID, and a full ID passes without a lookup; add `^{commit}`.
3. Using a short name in a script when a tag and a branch share it. Root cause: the lookup order puts `refs/tags/` before `refs/heads/`, so the tag wins.
4. Confusing `~2` with `^2`. Root cause: tilde counts generations along first parents, caret chooses a parent of a merge.
5. Storing abbreviated IDs. Root cause: an abbreviation is unique only in one repository at one time.

## PRODUCTION EXAMPLE

**[ANIMATION]** cards: cards=git_rev-parse_--show-toplevel:independent_of_the_calling_directory|--verify_--quiet_"refs/heads/$branch^{commit}":the_exit_status_is_the_answer|git_rev-parse_HEAD^{tree}:equal_tree_IDs_settle_it title=One_release_script,_three_questions_to_Git id=release at_2=86 at_3=45

Now, out of the lab. A backend team keeps a release script in a subdirectory of the repository, and it's called from CI, from laptops and from a cron host, each time from a different directory. The script begins with `git rev-parse --show-toplevel`, which makes it independent of the calling directory. To test whether the branch to release exists, it runs `git rev-parse --verify --quiet "refs/heads/$branch^{commit}"`, with nothing to parse: the exit status is the answer. And when two people disagree about what a build contained, they run `git rev-parse HEAD^{tree}` in both checkouts. Equal tree IDs settle it.

## PRACTICE EXERCISE

Your turn. Do Exercise 17.5, "What `git rev-parse` answers", in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md). It's a command-prediction exercise: write down the output of every `git rev-parse` call before you run it, and for IDs say whether two outputs are equal or different. Pay attention to what changes when HEAD is detached and when a file is staged.

The challenge is Exercise 16.8, "Scripts that read `.git` by hand", in the same file.

## INTERVIEW QUESTION

Question 54 of the CTO question bank:

> "Our deploy tool stores abbreviated IDs. What can go wrong, and what should it store?"

A strong answer says what an abbreviation is unique within, and over what time. It describes how the failure shows up later, as the repository grows, and names what the tool should store and how a script obtains that value safely, including the check that the value names a commit. The model answer is in the answers file. Give yours first, out loud.

**[PAUSE]**

## RECAP

**[ANIMATION]** step: rev.generations

**[ANIMATION]** say: Names_go_in,_one_object_ID_comes_out

Let's land this. Names go in, one object ID comes out.

You should now be able to say:

- `git rev-parse` is the resolver behind every command that takes a revision.
- Tilde counts generations along first parents; caret chooses a parent; `^{type}` peels to an object of that type; a leading colon reads the index.
- A short name is looked up in a fixed order, tags before branches, so scripts write full ref names.
- In scripts, `--verify --quiet` with `^{commit}` gives one ID or a failing exit status.
- Ask Git for the repository's directory, top level and formats; store full IDs.

## HOMEWORK

Read section 3.6 of [Chapter 3](../../textbook/ch03-git-internals.md).

Today you turned names into IDs, and repaired a script that guessed. Practise that before the next video: packfiles, pack indexes and delta compression. Until then, look at the state first and type second. See you in the next one.
