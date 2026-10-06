# V135: CODEOWNERS: what it is, where it lives, syntax, and last match wins

- **Part.** 5: GitHub
- **Module.** 23
- **Planned minutes.** 22
- **Prerequisites.** V012, V134
- **Textbook sections.** [Chapter 19](../../textbook/ch19-codeowners.md), sections 19.1 to 19.6
- **Demo scripts.** `labs/ch18/codeowners-vs-gitignore.sh`, `labs/ch18/codeowners-base.sh` (snippet `which-file`), then a screen walkthrough of Lab 23.2 in [`lab-manual/m23-governance.md`](../../lab-manual/m23-governance.md)

## HOOK

**[ON SCREEN]** One line: "We have a CODEOWNERS file. How did a change to the deployment workflow merge without the platform team seeing it?"

That's the question the chapter opens with. A CODEOWNERS file maps path patterns to the users and teams whom GitHub asks to review changes there. The textbook gives six ordinary answers. No rule required the review. A later line in the file took the path away from the team. The team has no explicit write access, so its line was skipped. The pull request was a draft. The file that counted was the one on the base branch. Or the person who merged could bypass the rule.

**[ANIMATION]** cards: id=six cards=No_rule_required_the_review|A_later_line_took_the_path_away|The_team_has_no_explicit_write_access|The_pull_request_was_a_draft|The_file_on_the_base_branch_counted|The_person_who_merged_could_bypass_the_rule dim=4,5,6 marks=2:ring title=Six_ordinary_answers at_1=0 at_2=5 at_3=10 at_4=15 at_5=20 at_6=25 at_marks=68

Each of the six is documented behavior. None is a bug. After this video you can explain the first three, and the next video covers the rest. Keep the second one in mind, the later line. It comes back.

## INTRODUCTION

**[ANIMATION]** end

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. You already know the gitignore pattern language from the video on ignoring files: patterns that tell Git which untracked files to leave alone. And from the last video you know how a ruleset, a named list of rules, blocks a merge. CODEOWNERS sits between the two. It borrows most of the gitignore pattern language, and it becomes binding only through a rule.

One statement frames everything that follows, and the chapter makes it in its first lines: Git can't evaluate a CODEOWNERS file. To Git it's an ordinary tracked file. Every statement about how GitHub matches patterns or requests reviews comes from GitHub's documentation. In the demonstration you'll see Git's ignore matcher at work, and each time I'll say whether GitHub is documented to agree with it or not. Where the two differ, the difference is the lesson.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- say what a CODEOWNERS file does when no rule refers to it;
- list the locations where the file is looked up and which one counts;
- write patterns and predict the owner of a path under "last match wins";
- name the gitignore features that do not work in CODEOWNERS;
- explain why an owner needs write access.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub.

**In one sentence.** `CODEOWNERS` is a text file in the repository that maps path patterns to users and teams, which GitHub uses to request reviews automatically and, if a rule says so, to require them.

**Precisely.** The documentation says: "Code owners are automatically requested for review when someone opens a pull request that modifies code that they own. Code owners are not automatically requested to review draft pull requests." A pull request proposes merging a head branch into a base branch, and a draft is one that still signals work in progress.

**[ANIMATION]** layers: id=who layers=Git:the_file,_its_content_and_its_history|GitHub:reads_the_file,_matches_the_changed_paths,_requests_reviewers|GitHub,_only_through_a_rule:blocks_the_merge_until_an_owner_approves title=Three_layers at_1=22 at_2=52 at_3=72

There are three layers, and you should be able to name them. The file, its content and its history belong to Git: it's an ordinary tracked file. Reading the file, matching the changed paths and requesting reviewers is done by GitHub. Blocking the merge until an owner approves is also GitHub, and only through a ruleset or a classic rule.

**[ANIMATION]** cards: id=where question=GitHub_uses_the_first_CODEOWNERS_file_it_finds cards=.github/:searched_first|the_repository_root:then_here|docs/:then_here|one_file_per_branch:main_and_release/1.0_can_differ|under_3_MB:a_larger_file_will_not_be_loaded at_1=4 at_2=8 at_3=12 at_4=50 at_5=70

**[ANIMATION]** step: 5

**Where it lives.** GitHub looks in `.github/`, then in the repository root, then in `docs/`. The documentation: "If `CODEOWNERS` files exist in more than one of those locations, GitHub will search for them in that order and use the first one it finds." Each file assigns the owners for a single branch, so `main` and `release/1.0` can have different owners. And the file must be under 3 MB in size. A larger one, in the documentation's words, "will not be loaded", which means no review requests at all.

**[ANIMATION]** end

**Syntax.** Each line is a pattern followed by one or more owners. Comments start with a hash sign. Owners are written as `@username` or `@org/team-name`. An email address that belongs to a user's account also works "in most cases", but not for managed user accounts.

Four rules of the syntax cause most of the surprises.

**[ANIMATION]** cards: id=syntax cards=several_owners:all_on_one_line|a_pattern_with_no_owner:removes_ownership|paths_are_case_sensitive:even_when_your_Mac_is_not|an_invalid_line_is_skipped:the_rest_of_the_file_still_applies numbered=on title=Four_rules_of_the_syntax

**[ANIMATION]** step: 1

First, several owners for one pattern go on one line. The documentation: "If the code owners are not on the same line, the pattern matches only the last mentioned code owner."

**[ANIMATION]** step: 2

Second, a pattern with no owner after it removes ownership. In the documented example, a line gives `/apps/` to one user and a later line names `/apps/github` with no owner. Changes under that directory then "can be made with the approval of any user who has write access".

**[ANIMATION]** step: 3

Third, paths are case sensitive, "because GitHub uses a case sensitive file system", even when your Mac isn't.

**[ANIMATION]** step: 4

Fourth, an invalid line is skipped, and the rest of the file still applies. So a typing error doesn't break the file. It silently removes one line.

**[ANIMATION]** cards: id=access question=Who_can_be_a_code_owner? cards=a_user:with_write_permissions_for_the_repository|a_team:visible,_and_with_write_permissions_as_a_team|insufficient_access:a_code_owner_will_not_be_assigned marks=3:bad at_1=17 at_2=38 at_3=5 at_marks=45

**[ANIMATION]** step: 2

**Owners need write access.** The textbook calls this the rule that fails silently most often. The people you choose as code owners must have write permissions for the repository. When the owner is a team, the team must be visible and the team itself must have write permissions, "even if all the individual members of the team already have write permissions directly, through organization membership, or through another team membership".

**[ANIMATION]** step: marks

The consequence is stated plainly: "If you specify a user or team that doesn't exist or has insufficient access, a code owner will not be assigned." So a secret team can't be an owner. And a team whose members can all push through the organization's base permission isn't an owner until the team itself is granted write access.

**[ANIMATION]** end

**Why the file only requests until a rule requires.** Without a rule, a code owner is a suggested reviewer whom the author may ignore. With the option "Require review from code owners" inside the pull request rule, "any pull request that modifies content with a code owner must be approved by that code owner before the pull request can be merged".

Quick quiz. One line gives a path to two teams, and the rule requires code owner review. Who has to approve? A, both teams. B, either team. Your answer?

**[PAUSE]**

B, either team. This is the detail that weakens many designs: "if code has multiple owners, an approval from any of the code owners will be sufficient". Two teams on one line means either team, not both.

A few more rows from the textbook's table. A changed path with no owner: the code-owner requirement asks nothing for that path. A draft: owners aren't requested until it's marked ready. The owner is the author: authors can't approve their own pull requests, so another owner of that path must. The textbook marks that last one as an inference from two documented rules, which Lab 23.2 lets you observe. It's a reason to list a team, not one person, as owner.

## MENTAL MODEL

**Analogy.** A building directory in the lobby tells a visitor whom to call. It locks no door. The lock is a separate device, a ruleset, that can be told to consult the directory.

The analogy breaks in one place, and it's the important place: this directory is read top to bottom, and the last line that fits wins.

**[ANIMATION]** match: id=m header=.github/CODEOWNERS rules=*:platform|/router/:routing|/router/priority.py:routing,_on-call|*.yaml:platform,_sre|docs/*:docs|/.github/:repo-admins numbers=2,5,6,9,12,15 title=The_owners_are_teams_of_@example-org paths=router/rules/eu.yaml:1+2+4|router/priority.py:1+2+3 wins=last at_1=30

**[ANIMATION]** step: rules

The documentation says: "Order is important; the last matching pattern takes the most precedence." So the procedure for one path is: go through the file from the top, note every line whose pattern matches the path, and keep only the last one. The owners on that line are the owners. Owners from earlier matching lines are replaced, not added.

**[ANIMATION]** step: 1

The trap is a general line placed after a specific one. In the sample file of the chapter, the path `router/rules/eu.yaml` matches three lines: the star, `/router/`, and `*.yaml`. The last of the three is `*.yaml`, so the platform and SRE teams own that path, and the routing team isn't asked. The rule of thumb from the textbook: put general patterns first and specific ones last, and remember that "specific" means "later in the file", not "longer".

**[ANIMATION]** walk: id=differ columns=in_a_pattern_file,gitignore,CODEOWNERS_(documented) rows=an_escaped_leading_hash_sign:works:does_not_work|negation_with_an_exclamation_mark:works:does_not_work|character_ranges_in_square_brackets:work:do_not_work|a_pattern_matches_a_directory:the_whole_directory_is_excluded:owners_go_to_files,_one_path_at_a_time marks=1.3:bad,2.3:bad,3.3:bad,4.3:hl mono=off title=Most_of_the_same_rules,_not_all at_1=58 at_2=74 at_3=85 at_4=30

**[ANIMATION]** step: 3

**How it differs from gitignore.** The patterns follow, in the documentation's words, "most of the same rules used in gitignore files". The documentation warns about three gitignore features that don't work: escaping a leading hash sign with a backslash, negating a pattern with an exclamation mark, and character ranges in square brackets.

**[ANIMATION]** step: 4

And there's a fourth difference that has no syntax of its own. Gitignore works on directories first: when a pattern matches a directory, Git excludes the whole directory and never looks at the files inside. CODEOWNERS assigns owners to files, one path at a time.

## DIAGRAM

**[DIAGRAM]** Put the sample file on the left with its line numbers, and the paths on the right. Draw one arrow at a time, and for each arrow first mark every line that matches, then keep the last.

```text
  .github/CODEOWNERS on main                          changed path
  --------------------------------------------        -----------------------------
   2  *                    @example-org/platform
   5  /router/             @example-org/routing   <--- router/classify.py     (matches 2, 5)
   6  /router/priority.py  @example-org/routing
                           @example-org/on-call   <--- ?  router/priority.py
   9  *.yaml               @example-org/platform
                           @example-org/sre       <--- router/rules/eu.yaml   (matches 2, 5, 9)
                                                  <--- ?  config/routing.yaml
  12  docs/*               @example-org/docs      <--- docs/README.md         (matches 2, 12)
                                                       ?  docs/runbooks/escalation.md
                                                       ?  Docs/guide.md
  15  /.github/            @example-org/repo-admins    ?  .github/workflows/ci.yaml
```

Start with two of the arrows. `router/classify.py` matches lines 2 and 5, so line 5 decides: the routing team. `docs/README.md` matches lines 2 and 12: the docs team.

Try it now, thirty seconds, on paper. Take the first question mark, `router/priority.py`. Write down every line that matches, and keep the last. I'll wait.

**[PAUSE]**

**[ANIMATION]** step: m.2

Lines 2, 5 and 6 match, and line 6 is the last. So the owners are the routing team and the on-call team. Both are on line 6. The drawing only wraps it. The other four question marks are yours, in the pattern exercises of section 19.16.

**[DIAGRAM]** Three arrows are drawn, because the textbook resolves those three paths in its text. Four of the five question marks are still yours: they are among the pattern exercises of section 19.16. For each, mark the matching lines and keep the last. Two of them depend on a rule you have heard in the last five minutes and will see in the terminal in the next five.

**[ON SCREEN]** The root-cause box of section 19.5, one line at a time. Observed behavior: `git check-ignore` says `docs/*` matches `docs/build-app/troubleshooting.md`, and GitHub's CODEOWNERS documentation says it does not. Git state: none involved; this is pattern matching on path strings. Mechanism: gitignore patterns are applied to each directory on the way down; `docs/*` matches the directory `docs/build-app`, and everything below an excluded directory is excluded, while CODEOWNERS assigns owners to files, one path at a time. Root cause: two matchers with a shared pattern language and different jobs; one prunes directory walks, the other labels files. Why Git does this: skipping an ignored directory without reading it is what makes status fast. Correct fix: do not test CODEOWNERS with check-ignore; reason from the documented rules, then confirm on GitHub. Prevention: to own a whole subtree write the directory form, `/docs/`, not `docs/*`.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay with `labs/run ch18/codeowners-vs-gitignore`. Every command in this replay is `git check-ignore -v --no-index`, which is 🟢 SAFE: it changes nothing. Say this once, clearly: what you see is Git's matcher, not GitHub's. It answers a different question.

Into the lab. Every command in this replay is `git check-ignore`, which names the ignore pattern that decides for a path. It's 🟢 SAFE: it changes nothing. And remember: this is Git's matcher, not GitHub's.

**Step 1: last match wins, where the two agree.**

```bash
printf '*.py\n/router/*.py\n/router/priority.py\n' > .gitignore
git check-ignore -v --no-index tests/test_classify.py router/classify.py router/priority.py
```

Three patterns, three paths. `router/priority.py` matches all three patterns. Which line will be named for it? Say it out loud.

**[PAUSE]**

<!-- snippet: ch18/codeowners-vs-gitignore/01-last-match-wins -->
```text
# Three patterns in one gitignore-format file. check-ignore -v names the pattern that decides:
$ printf '*.py\n/router/*.py\n/router/priority.py\n' > .gitignore
$ git check-ignore -v --no-index tests/test_classify.py router/classify.py router/priority.py
.gitignore:1:*.py	tests/test_classify.py
.gitignore:2:/router/*.py	router/classify.py
.gitignore:3:/router/priority.py	router/priority.py
```
<!-- /snippet -->

The `-v` option prints the file, the line number and the pattern that decided. For `router/priority.py` it's line 3, the last of the three matches. Within one file, and as long as only files are involved, Git also lets the last matching pattern decide.

**Step 2: anchoring.**

```bash
printf 'apps/\n/docs/\n**/logs\n' > .gitignore
git check-ignore -v --no-index apps/a.py services/billing/apps/a.py docs/a.md guide/docs/a.md build/logs/x.log logs/x.log
```

Six paths. One of them won't be listed. Which? Make your prediction.

**[PAUSE]**

<!-- snippet: ch18/codeowners-vs-gitignore/02-anchoring -->
```text
$ printf 'apps/\n/docs/\n**/logs\n' > .gitignore
$ git check-ignore -v --no-index apps/a.py services/billing/apps/a.py docs/a.md guide/docs/a.md build/logs/x.log logs/x.log
.gitignore:1:apps/	apps/a.py
.gitignore:1:apps/	services/billing/apps/a.py
.gitignore:2:/docs/	docs/a.md
.gitignore:3:**/logs	build/logs/x.log
.gitignore:3:**/logs	logs/x.log
# guide/docs/a.md is not listed: /docs/ is anchored to the top level.
```
<!-- /snippet -->

`apps/` without a leading slash matches an `apps` directory anywhere. That agrees with the documented CODEOWNERS meaning, "any file in an `apps` directory anywhere in your repository". `/docs/` with a leading slash is anchored to the top level, so `guide/docs/a.md` is missing from the output. And `**/logs` matches a `logs` directory at any depth.

**Step 3: where the two part ways.**

```bash
printf '*\n*.py\n' > .gitignore
git check-ignore -v --no-index setup.py tests/test_classify.py
```

A catch-all first, then a more specific pattern. By "last match wins" you'd expect line 2 for both paths. Predict what Git prints.

**[PAUSE]**

<!-- snippet: ch18/codeowners-vs-gitignore/03-directory-capture -->
```text
# Where the two part ways: a catch-all first line, then a more specific pattern.
$ printf '*\n*.py\n' > .gitignore
$ git check-ignore -v --no-index setup.py tests/test_classify.py
.gitignore:2:*.py	setup.py
.gitignore:1:*	tests/test_classify.py
# Git stops at the directory tests/, which the first line already matches.
# CODEOWNERS documentation: after "*", a later "*.js" line owns every JS file.
```
<!-- /snippet -->

For `tests/test_classify.py` Git reports line 1. Git stopped at the directory `tests/`, which the first line already matches, and never looked at the file. CODEOWNERS is documented to behave differently: in GitHub's own example, a star followed by `*.js` gives every JavaScript file to the JavaScript owner.

**Step 4: the same mechanism behind a documented example.**

```bash
printf 'docs/*\n' > .gitignore
git check-ignore -v --no-index docs/getting-started.md docs/build-app/troubleshooting.md
```

<!-- snippet: ch18/codeowners-vs-gitignore/04-docs-star -->
```text
# The same mechanism behind a documented example: docs/* and nested files.
$ printf 'docs/*\n' > .gitignore
$ git check-ignore -v --no-index docs/getting-started.md docs/build-app/troubleshooting.md
.gitignore:1:docs/*	docs/getting-started.md
.gitignore:1:docs/*	docs/build-app/troubleshooting.md
# Git ignores the nested file too, because docs/* matches the directory docs/build-app.
# CODEOWNERS documentation: docs/* does not match docs/build-app/troubleshooting.md.
```
<!-- /snippet -->

Git ignores the nested file too. The CODEOWNERS documentation says `docs/*` matches files directly in `docs/`, "but not further nested files". This is the root-cause box you saw a moment ago. If you had used this command as a CODEOWNERS tester, you would now believe the docs team owns a file that falls to the default owner.

**Step 5: the three documented exceptions, which all work in Git.**

```bash
printf '*.yaml\n!config/routing.yaml\n' > .gitignore
git check-ignore -v --no-index config/routing.yaml deploy/values.yaml
```

<!-- snippet: ch18/codeowners-vs-gitignore/05-negation -->
```text
# Documented as unsupported in CODEOWNERS: ! negation. In gitignore it works:
$ printf '*.yaml\n!config/routing.yaml\n' > .gitignore
$ git check-ignore -v --no-index config/routing.yaml deploy/values.yaml
.gitignore:2:!config/routing.yaml	config/routing.yaml
.gitignore:1:*.yaml	deploy/values.yaml
```
<!-- /snippet -->

In gitignore the negation on line 2 decides for `config/routing.yaml`. In CODEOWNERS it's documented not to work.

```bash
printf 'shard-[0-3].yaml\n' > .gitignore
git check-ignore -v --no-index shard-2.yaml shard-7.yaml
```

<!-- snippet: ch18/codeowners-vs-gitignore/06-range -->
```text
# Documented as unsupported in CODEOWNERS: [ ] character ranges. In gitignore they work:
$ printf 'shard-[0-3].yaml\n' > .gitignore
$ git check-ignore -v --no-index shard-2.yaml shard-7.yaml
.gitignore:1:shard-[0-3].yaml	shard-2.yaml
```
<!-- /snippet -->

The range matches `shard-2.yaml` and not `shard-7.yaml`. In CODEOWNERS ranges are documented not to work.

<!-- snippet: ch18/codeowners-vs-gitignore/07-hash -->
```text
# Documented as unsupported in CODEOWNERS: a leading # escaped with a backslash.
$ printf '\\#generated.md\n' > .gitignore
$ cat .gitignore
\#generated.md
$ git check-ignore -v --no-index "#generated.md"
.gitignore:1:\#generated.md	#generated.md
```
<!-- /snippet -->

And the escaped hash sign: a pattern in Git, unsupported in CODEOWNERS. That's why a pattern that "works locally" can do nothing in CODEOWNERS.

**Step 6: case.**

<!-- snippet: ch18/codeowners-vs-gitignore/08-case -->
```text
# CODEOWNERS paths are always case sensitive. Git depends on core.ignoreCase, which git init
# switches on when the file system ignores case, as the default macOS file system does:
$ printf '/docs/\n' > .gitignore
$ git -c core.ignoreCase=false check-ignore -v --no-index Docs/a.md
[exit status: 1]
$ git -c core.ignoreCase=true check-ignore -v --no-index Docs/a.md
.gitignore:1:/docs/	Docs/a.md
[exit status: 0]
```
<!-- /snippet -->

Read the two exit statuses. With `core.ignoreCase` false, `Docs/a.md` doesn't match `/docs/`. With it true, it does. `git init` switches that setting on when the file system ignores case, as the default macOS file system does. GitHub never ignores case.

**Step 7: which file counts.** Replay `labs/run ch18/codeowners-base` and stop after the first snippet.

<!-- snippet: ch18/codeowners-base/01-which-file -->
```text
# The documented search order, applied to the base branch of the pull request:
$ for p in .github/CODEOWNERS CODEOWNERS docs/CODEOWNERS; do git cat-file -e origin/main:$p 2>/dev/null && echo "exists on main: $p"; done
exists on main: .github/CODEOWNERS
exists on main: docs/CODEOWNERS
# The first one found is used. Its size in bytes (the documented limit is 3 MB):
$ git cat-file -s origin/main:.github/CODEOWNERS
531
```
<!-- /snippet -->

The search order and the size are plain Git questions about the base branch. `git cat-file -e` tests whether an object exists. `git cat-file -s` prints its size. Two files exist on `main`. The one in `.github/` is used. The older `docs/CODEOWNERS` is dead text that will mislead whoever finds it. Delete it.

**[ON SCREEN]** Lower third: GitHub. Screen walkthrough.

On your practice repository, following Lab 23.2. The interface changes. The lab text and the linked documentation are the reference, and no GitHub output was captured by the authors. In this video only look: open the CODEOWNERS file in the browser after step 2 of the lab. The documentation says errors are highlighted on that page. Then browse to a file under `router/` and look for the indication of who owns it. The enforcement part of the lab belongs to the next video.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Owners are requested and ignored.** Root cause: no rule requires code owner review, so the file only suggests reviewers.
2. **The wrong team is requested.** Root cause: a general pattern stands after a specific one, and the last matching line replaces the earlier owners.
3. **Nobody is requested for a team's line.** Root cause: the team has no explicit write access or is a secret team, so no code owner is assigned.
4. **`docs/*` was meant as "everything under docs".** Root cause: that form covers files directly in the directory; nested files fall to the default owner. The directory form is `/docs/`.
5. **Owners of one pattern were written on two lines.** Root cause: only the last line for a pattern counts.

## PRODUCTION EXAMPLE

**[ANIMATION]** match: id=prod header=CODEOWNERS rules=/router/:routing|*.yaml:platform,_sre paths=router/rules/eu.yaml:1+2 wins=last title=A_later,_more_general_line at_rules=40

**[ANIMATION]** step: rules

Now, out of the lab. An ML platform team keeps service code, model configuration and deployment values in one repository. The CODEOWNERS file gives `/router/` to the routing team. Months later someone adds a line near the end that gives `*.yaml` to the platform and SRE teams, "so that configuration always gets a second pair of eyes".

**[ANIMATION]** step: 1

From that merge on, a change to `router/rules/eu.yaml` requests platform and SRE and no longer requests the routing team, who are the people that understand the routing rules. Nothing fails. No error appears. The first sign is a routing change that reached production with an approval from someone who couldn't judge it.

The diagnosis takes one minute if you read the file bottom-up for the path. The fix is to move the general line to the top. The prevention is a review habit for the file itself: for every new line, ask which existing owners lose which paths. That's the later line from the opening.

## PRACTICE EXERCISE

**[ANIMATION]** end

Your turn. Do Exercise 23.5, "Eight paths, one CODEOWNERS file", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md). Reason from the documented rules. Don't use `git check-ignore`. You've seen where it disagrees.

Before you look anything up, predict for each of the eight paths the one line that decides and who is requested. Then list the faults in the file.

The challenge is Exercise 23.7, "Protect a monorepo", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q237: "Explain "last match wins" in CODEOWNERS with an example where a later, more general pattern takes a path away from a specific team."

**[PAUSE]**

Answer out loud first. A strong answer states the rule in one sentence and attributes it to GitHub, not to Git. It gives a concrete file of three or four lines and one path, lists every line the path matches, and names the deciding line. It says that earlier owners are replaced, not added. It says what the symptom looks like in practice: no error, the wrong reviewers. And it ends with the ordering rule that prevents it, and how you would confirm what GitHub thinks.

## RECAP

**[ANIMATION]** step: six.marks

Let's land this. Three of the six answers from the opening are now yours to explain: no rule, a later line, and no explicit write access.

You should now be able to say:

- CODEOWNERS is a tracked file that GitHub reads to request reviews; only a rule makes those reviews required.
- GitHub looks in `.github/`, the root and `docs/`, in that order, and uses the first file it finds.
- For each changed path the last matching line decides and replaces earlier owners.
- Negation, character ranges and the escaped hash sign do not work, `docs/*` covers one level, and paths are case sensitive.
- An owner must have write access, and a team must be visible and hold write access as a team.

## HOMEWORK

Read sections 19.1 to 19.6 of [Chapter 19](../../textbook/ch19-codeowners.md). Do the pattern exercises of section 19.16.

Today you read a CODEOWNERS file the way GitHub is documented to read it: top to bottom, keeping the last match. Try the eight paths on paper before the next video. Next time: CODEOWNERS in force, and why the base branch decides. Until then, look at the state first and type second. See you in the next one.
