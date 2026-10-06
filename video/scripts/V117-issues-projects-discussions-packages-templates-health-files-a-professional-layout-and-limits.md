# V117: Issues, Projects, Discussions, Packages, templates, health files, a professional layout, and limits

- **Part.** 5: GitHub
- **Module.** 19
- **Planned minutes.** 26
- **Prerequisites.** V115
- **Textbook sections.** [Chapter 15](../../textbook/ch15-github.md), sections 15.8 to 15.11, 15.13 to 15.15 and 15.19
- **Demo scripts.** `labs/ch15/repo-layout.sh`, `labs/ch15/large-objects.sh`; GitHub-side walkthrough of Lab 19.1

## HOOK

**[ON SCREEN]** A merged pull request: "Fixes #812". Below it, issue 812: Open.

A fix is merged into `release/2.4` with "Fixes #812" in the description. The issue stays open, and the customer is told it is unresolved. The engineer insists the fix shipped. Support insists the tracker says otherwise. Your CTO asks: what failed?

Nothing failed. The pull request didn't target the default branch, and the keyword is interpreted only there. Two systems were involved, text in one and a rule in the other, and each did exactly what it documents. Hold on to issue 812. An issue can stay open for three reasons, and you'll be able to name all of them.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video is a tour of the platform features around the code, with the map from video 115 in your hand. For each feature the question is the same: is it Git data, a GitHub object, or Git data that GitHub interprets? Git data is commits and refs, and it travels with a clone. A GitHub object lives in GitHub's database.

The order: issues and the keywords that close them. Labels and milestones. Projects, Discussions and wikis. Packages. Then the files that GitHub reads, the community health files and templates. A professional repository layout, file by file. The repository limits. And organization governance in one table.

Two local replays from `labs/ch15`, `repo-layout.sh` and `large-objects.sh`, and then a screen walkthrough of Lab 19.1 in a practice repository. For the walkthrough the usual reminder applies: the interface changes, the lab text and the linked documentation are the reference, and no GitHub output was captured.

Every local command here reads state: 🟢 SAFE.

## LEARNING OBJECTIVES

After this video you can:

- Explain how a closing keyword links a commit or pull request to an issue and three reasons it does not close one.
- Say what Projects, Discussions, wikis and Packages are for, as the sections describe them.
- Create issue forms, a pull request template and the community health files.
- Justify each file of the professional repository layout.
- State the repository limits the section lists and find the commit that added a large file.

## CONCEPT

Issues. In one sentence: an issue is a numbered record in GitHub's database for a unit of work or a report, which since 2025 can have a type, a parent, children and dependencies.

To the REST API, "every pull request is an issue, but not every issue is a pull request". That's why `#12` can be either. A pull request, remember, is a proposal to merge one branch into another.

**[ANIMATION]** walk: id=structure columns=added,limit,since rows=sub-issues:100_per_parent,_eight_levels_deep:9_April_2025|issue_types:up_to_25_per_organization:-|dependencies:50_links_per_relationship_type:21_August_2025|issue_fields:four_default_fields:2_July_2026 mono=off title=Issues:_the_structure_added_in_2025_and_2026 at_1=8 at_2=30 at_3=45 at_4=65

**[ANIMATION]** step: 4

The structure added in 2025 and 2026. Sub-issues: up to 100 per parent, eight levels deep, generally available since the ninth of April 2025. Issue types: defined per organization, up to 25, with the defaults task, bug and feature. Dependencies, "blocked by" and "blocking": up to 50 links per relationship type, since the twenty-first of August 2025. Issue fields: typed metadata defined per organization, with four default fields, since the second of July 2026. Types and fields belong to an organization: one more thing a personal account doesn't have.

**[ANIMATION]** end

Closing keywords. Nine words link a pull request or a commit to an issue: `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved`, followed by `#N` for the same repository or `OWNER/REPO#N` for another, in any letter case, with an optional colon.

**[ON SCREEN]** Three rules.

Three rules explain every "why did it not close" question. One: in a pull request description the keywords are interpreted only when the pull request targets the default branch, the branch a repository presents first. Against any other branch they're ignored: no link is made and nothing closes. Two: in a commit message the issue closes when the commit reaches the default branch, and the pull request that carried the commit isn't listed as linked. Three: the issue closes at merge time, not when the pull request is opened.

Quick quiz. A commit message says "Fixes #812", and the commit sits on a feature branch. When does the issue close: when the commit is pushed, when the pull request opens, or when the commit reaches the default branch? Say it out loud.

**[PAUSE]**

**[ANIMATION]** cards: id=rules question=Why_did_it_not_close? cards=In_a_pull_request_description:only_when_it_targets_the_default_branch|In_a_commit_message:when_the_commit_reaches_the_default_branch|At_merge_time:not_when_the_pull_request_is_opened numbered=on marks=2:ring pace=quick

**[ANIMATION]** step: marks

When the commit reaches the default branch. That's rule two. If you said "when the pull request opens", rule three is the one to reread: opening a pull request closes nothing.

And the layer: the keyword is text in a commit object or in a database field. Git does nothing with it. It also travels with the message. A cherry-picked or rebased copy of the commit carries the same words, and they act when that copy reaches a default branch.

**[ANIMATION]** end

For daily work, `gh issue create`, `list`, `view`, `edit`, `close` and `develop`. A version caveat: the installed GitHub CLI 2.88.1 has no flags for types, parents or dependencies. `gh issue create --type` and `--parent` arrived in 2.94.0.

Labels and milestones. A label classifies issues, pull requests and discussions within one repository. Creating a label needs Write, and applying one needs Triage. Labels are more than decoration when something reads them: an issue form can apply labels, generated release notes group pull requests by label, and workflows can react to them. A milestone groups issues and pull requests toward a date. It is not a Git tag and not a release: a milestone called `v0.3.0` promises nothing about which commit ships.

**[ANIMATION]** walk: id=around columns=feature,what_it_is,note rows=Projects:the_planning_layer_over_issues_and_pull_requests:owned_by_a_user_or_an_organization|Discussions:a_forum_beside_the_issue_tracker:-|wiki:documentation_in_a_second_Git_repository:outside_pull_requests_and_rulesets mono=off title=Around_the_code at_1=5

**[ANIMATION]** step: 1

Projects is the planning layer: "an adaptable table, board, and roadmap" over issues and pull requests, owned by a user or an organization, not by a repository. An outdated-advice note: "Projects (classic)", a board attached to one repository, was sunset on GitHub.com on the twenty-third of August 2024.

**[ANIMATION]** step: 2

Discussions is a forum beside the issue tracker. The working rule from the textbook: an issue can be done and closed. A question or an open-ended idea is a discussion.

**[ANIMATION]** step: 3

A wiki is documentation in a second Git repository. Because it's a separate repository, a wiki isn't reviewed through pull requests, isn't covered by the rulesets of the main repository, and isn't included when you clone or mirror the code. Documentation that must be reviewed with the code belongs in `docs/`.

**[ANIMATION]** end

Packages. GitHub Packages hosts registries for npm, RubyGems, Maven, Gradle, Docker and NuGet. The Container registry at `ghcr.io` is the home for Docker and OCI images.

**[ANIMATION]** cards: id=packages question=GitHub_Packages:_four_facts cards=Not_Git_data:not_part_of_a_repository|Authentication:a_personal_access_token_(classic),_or_GITHUB__TOKEN_in_a_workflow|Public_packages_are_free|Provenance_is_separate_from_storage:an_artifact_attestation numbered=on at_1=4 at_2=30 at_4=8

**[ANIMATION]** step: 2

Four facts. A package is not Git data and not part of a repository: an image is "not linked to a repository by default". Authentication is an exception to the token advice of the next videos: "GitHub Packages only supports authentication using a personal access token (classic)", while inside a workflow the job's `GITHUB_TOKEN` is used.

**[ANIMATION]** step: 4

Public packages are free. And provenance is separate from storage: an artifact attestation is a signed claim about which workflow run built an artifact from which commit. The old registry `docker.pkg.github.com` was closed on the twenty-fourth of February 2025. Use `ghcr.io`.

**[ANIMATION]** end

Health files. In one sentence: community health files are tracked files with well-known names that GitHub finds and uses to guide the people who interact with a repository. GitHub looks for each file in `.github/`, then the repository root, then `docs/`.

**[ANIMATION]** walk: id=health columns=tracked_file,what_GitHub_does_with_it rows=README.md:rendered_on_the_front_page|LICENSE:detected_and_shown|CONTRIBUTING.md:linked_when_someone_opens_an_issue_or_pull_request|SECURITY.md:shown_as_the_security_policy|CODE__OF__CONDUCT.md:counts_in_the_community_profile|.github/ISSUE__TEMPLATE/:offered_in_the_new_issue_chooser|pull__request__template.md:pre-fills_the_description_of_a_new_pull_request title=Written_in_Git,_acted_on_by_GitHub at_1=3 at_2=22 at_4=40 at_5=68 at_7=30

**[ANIMATION]** step: 2

`README.md` is rendered on the front page. `LICENSE`: GitHub detects and shows the license. Without one, default copyright applies and nobody is permitted to reuse the code.

**[ANIMATION]** step: 5

`CONTRIBUTING.md` is linked when someone opens an issue or pull request. `SECURITY.md` is shown as the security policy. `CODE_OF_CONDUCT.md` counts in the community profile.

**[ANIMATION]** step: 7

The files under `.github/ISSUE_TEMPLATE/` are offered in the "new issue" chooser. `pull_request_template.md` pre-fills the description of a new pull request. Both templates are read from the default branch. Unlike settings, these files are versioned and reviewed like code.

**[ANIMATION]** end

One caveat the textbook marks unverified: GitHub's syntax page still carries the note that issue forms are in public preview, and the course's research could not determine whether that note is current or stale.

Limits. GitHub's limits come in three kinds: enforced, recommended, and display limits. Mixing them up produces both needless worry and real outages.

**[ON SCREEN]** The table of section 15.15.

Enforced: one file in a push gives a warning above 50 mebibytes and is blocked above 100 mebibytes. One file added in the browser: 25 mebibytes. One push: 2 gigabytes. "Rebase and merge": 100 commits. Release assets: 1,000 per release, each under 2 gibibytes.

Recommended: repository size "ideally less than 1 GB, and less than 5 GB is strongly recommended" on one page, and 10 gigabytes on disk as a recommended maximum on another. The two sit on two pages and differ. Treat 1 gigabyte as the target and 10 gigabytes as the point where GitHub expects problems. Also recommended: 3,000 entries in one directory, a directory depth of 50, 5,000 branches. Display: a pull request diff of 20,000 lines or 1 megabyte that can be loaded, and 300 files. And 250 commits listed in a pull request or comparison.

The file limit applies to every object a push sends, not to the files in your working tree. A file you deleted in a later commit is still in history, and a first push sends all of history.

Governance in brief, each item a GitHub object that no clone carries. Base permission, teams and roles. Required two-factor authentication. A personal access token policy. Repository rulesets and organization rulesets. Custom properties. The audit log, 180 days and searchable. And on Enterprise Cloud, SAML single sign-on, IP allow lists, custom roles and enterprise policies. One caveat marked unverified in the book: GitHub's documentation contradicts itself on whether organization rulesets need Enterprise or Team, and the course prefers the later sources, which say Team.

## MENTAL MODEL

Keep the manuscript in the publisher's office from video 115, and remember where that analogy broke: the office reads instructions written inside the manuscript.

**[ANIMATION]** step: health.7

This whole video is that break, item by item. The issue form, the pull request template, the security policy, the closing keyword: each is written in the manuscript, in Git, and acted on by the office, GitHub. So each has two halves you can check separately. Is the text there, in the right place, on the right branch? That's a Git question. Did the platform act on it? That's a GitHub question, and its conditions are in the documentation.

When a platform feature "does not work", check the Git half first. It's the half you can prove from a terminal.

## DIAGRAM

**[DIAGRAM]** The layout of section 15.14, with one line of purpose beside each entry.

```text
project/
├── .github/
│   ├── workflows/                  CI and delivery, reviewed like code; deserves a code owner
│   ├── CODEOWNERS                  who is asked to review which paths
│   └── pull_request_template.md    every description answers: what, why, how tested
├── src/                            the package, importable only on purpose
├── tests/                          kept apart, so tests are not shipped with the package
├── docs/                           documentation that changes with the code it describes
├── scripts/                        release and deploy commands as files with history
├── configs/                        configuration without secrets
├── .gitignore                      keeps build output and local secret files out of the index
├── README.md                       what this is, how to run it, where to go next
├── LICENSE                         the terms of reuse
├── CONTRIBUTING.md                 how a change gets in
├── SECURITY.md                     where to report a vulnerability privately
├── pyproject.toml                  project metadata and tool configuration
└── Dockerfile                      how the service image is built
```

This layout is a convention, not a GitHub requirement. GitHub reads the health files and nothing else in it.

Go down the tree and ask of each line: who reads it? `.github/workflows/` is read by GitHub Actions. Write can change what runs with the repository's secrets, which is why this directory deserves a code owner. `CODEOWNERS` is only a request until a rule requires it. `.gitignore` is read by Git, and it doesn't untrack what is already tracked. `LICENSE` is read by GitHub and by lawyers: without it nobody outside may use the code, whatever the visibility. `SECURITY.md` exists so that the first report of a vulnerability isn't a public issue.

## LIVE TERMINAL DEMO

**[TERMINAL]**

```bash
labs/run ch15/repo-layout
```

```bash
git ls-files
```

The diagram has a `.github/workflows/` directory. Will `git ls-files` list it? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch15/repo-layout/01-tracked-files -->
```text
$ git ls-files
.github/CODEOWNERS
.github/ISSUE_TEMPLATE/1-bug.yml
.github/ISSUE_TEMPLATE/2-feature.yml
.github/ISSUE_TEMPLATE/config.yml
.github/pull_request_template.md
.gitignore
CONTRIBUTING.md
Dockerfile
LICENSE
README.md
SECURITY.md
configs/default.yaml
docs/architecture.md
pyproject.toml
scripts/release.sh
src/prompt_registry/__init__.py
src/prompt_registry/registry.py
tests/test_registry.py
```
<!-- /snippet -->

It isn't there. Git tracks files, not directories, so the directory appears with the first workflow file, in Part 6.

```bash
cat .github/ISSUE_TEMPLATE/1-bug.yml
```

<!-- snippet: ch15/repo-layout/02-issue-form -->
```text
$ cat .github/ISSUE_TEMPLATE/1-bug.yml
name: Bug report
description: Something does not work as documented.
title: "[Bug]: "
labels: ["bug"]
body:
  - type: markdown
    attributes:
      value: |
        Thank you for reporting. Do not report vulnerabilities here: see SECURITY.md.
  - type: textarea
    id: what-happened
    attributes:
      label: What happened?
      description: What did you do, what did you expect, and what happened instead?
    validations:
      required: true
  - type: input
    id: commit
    attributes:
      label: Commit
      description: The output of `git rev-parse --short HEAD` in your clone.
    validations:
      required: true
  - type: textarea
    id: logs
    attributes:
      label: Relevant output
      description: Paste the command and its output. It is formatted as code automatically.
      render: shell
```
<!-- /snippet -->

An issue form is a YAML file that turns the free-text issue into a form with required fields. Point at `labels: ["bug"]`: the form applies a default label. Point at the `input` element that asks for the output of `git rev-parse --short HEAD`: the form asks the reporter for a commit ID. The file was parsed with a YAML parser for the course. Only GitHub validates a form.

```bash
cat .github/ISSUE_TEMPLATE/config.yml
cat .github/pull_request_template.md
```

<!-- snippet: ch15/repo-layout/03-chooser-and-pr-template -->
```text
$ cat .github/ISSUE_TEMPLATE/config.yml
blank_issues_enabled: false
$ cat .github/pull_request_template.md
## What changed

<!-- One or two sentences. Link the issue: "Fixes #123" closes it when this merges into the default branch. -->

## Why

## How it was tested

- [ ] `python3 -m unittest discover -s tests` passes
- [ ] New behavior has a test

## Checklist

- [ ] The pull request does one thing
- [ ] No credentials, tokens, datasets or model files are in the diff
```
<!-- /snippet -->

`blank_issues_enabled: false` removes the blank issue from the chooser for people with the Read or Triage role. People with Write still see it. The pull request template is plain Markdown. Content inside an HTML comment is hidden in the rendered description, so the comment guides the author and doesn't clutter the result. Issue forms can't be used for pull requests.

Two checks that belong to the layout.

```bash
printf 'LLM_API_KEY=FAKE-KEY-for-the-lab\n' > .env
git status --short
git check-ignore -v .env
```

A new file named `.env`. What does `git status --short` print? Make your prediction.

**[PAUSE]**

<!-- snippet: ch15/repo-layout/04-ignored-secret -->
```text
$ printf 'LLM_API_KEY=FAKE-KEY-for-the-lab\n' > .env
$ git status --short
$ git check-ignore -v .env
.gitignore:10:.env	.env
```
<!-- /snippet -->

Nothing: the file is ignored. `git check-ignore -v` names the rule: the file, the line number and the pattern. A local secret file must be ignored before the first commit.

Try it now, thirty seconds, in a repository of your own. Pick a file you believe is ignored, and run `git check-ignore -v` on it. I'll wait.

**[PAUSE]**

You should see the same three parts as on screen: a file of rules, a line number and a pattern.

```bash
python3 -m unittest discover -s tests 2>&1 | tail -1
git status --short
```

<!-- snippet: ch15/repo-layout/05-tests -->
```text
$ python3 -m unittest discover -s tests 2>&1 | tail -1
OK
$ git status --short
```
<!-- /snippet -->

The tests run from a fresh clone with one documented command and leave the working tree clean.

**[TERMINAL]** Limits.

```bash
labs/run ch15/large-objects
```

```bash
git log --oneline -3
git ls-files | grep -c classifier
```

<!-- snippet: ch15/large-objects/01-gone -->
```text
$ git log --oneline -3
39c4105 Move the classifier out of Git
c7182c9 Add trained intent classifier
bf7889c Add contribution guide, security policy and templates
$ git ls-files | grep -c classifier
0
```
<!-- /snippet -->

A model file was added in one commit and moved out of Git in the next. No tracked file has "classifier" in its name.

```bash
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | awk '$1 == "blob"' | sort -k2,2nr | head -3
```

The file is gone from the working tree. Is it gone from what a first push would send? Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch15/large-objects/02-still-in-history -->
```text
$ git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | awk '$1 == "blob"' | sort -k2,2nr | head -3
blob 3145728 models/intent-classifier.bin
blob 1324 tests/test_registry.py
blob 996 src/prompt_registry/registry.py
```
<!-- /snippet -->

It's the largest blob of the repository: 3 mebibytes, still reachable. If you said gone, that's the natural answer, and it's the one behind many rejected pushes. This is the pipeline from Part 4.

```bash
git log --oneline --diff-filter=A -- models/intent-classifier.bin
```

<!-- snippet: ch15/large-objects/03-which-commit -->
```text
$ git log --oneline --diff-filter=A -- models/intent-classifier.bin
c7182c9 Add trained intent classifier
```
<!-- /snippet -->

`--diff-filter=A` finds the commit that added the path: `c7182c9`.

**[ANIMATION]** graph: id=big ...older-bf7889c-c7182c9-39c4105 main; HEAD=main; title:Removed_at_the_tip,_still_in_history => + note:c7182c9:adds_the_file; note:39c4105:removes_it; name:behind; say:A_first_push_sends_all_of_this_history

**[ANIMATION]** step: behind

Here's the picture. The branch `main` points at `39c4105`, the commit that removed the file. Behind it sits `c7182c9`, which added it, and a first push sends all of that history. Had the file been 300 mebibytes, the push would be rejected for that commit. The remedies are rewriting unpushed history, or Git LFS. For a model file the better answer is usually a registry.

**[ON SCREEN]** GitHub walkthrough, Lab 19.1, in the normal shell. The interface changes; the lab text and the documentation are the reference. No output is shown.

The lab creates a free organization in the browser, copies the practice repository template, and makes the first commit locally. Then one command creates the repository in the organization and pushes. Replace `YOUR-ORG` with your own.

```bash
gh repo create YOUR-ORG/practice-repo --public --source=. --remote=origin --push \
  --description "Practice repository for the Git and GitHub mastery course"
git ls-remote origin
gh repo edit YOUR-ORG/practice-repo --delete-branch-on-merge --enable-wiki=false --enable-projects=false
gh repo view --web
gh issue create --web
```

Say what each step created. `gh repo create` created a GitHub object, the repository, added a remote to your `.git/config`, and pushed Git data. `gh repo edit` changed three settings: GitHub objects.

Now show the files taking effect after the push. With `gh issue create --web`, the browser opens the chooser: according to the documentation, it offers the two forms by their `name` and `description`, and no blank issue for a reader. Open the bug form: the required fields are the ones the YAML declared. Close the tab without creating an issue. Then start a pull request from any branch in the browser: the description field is pre-filled with the template. Finally open the community profile, under Insights, Community Standards, and read the checklist against your files.

## COMMON MISTAKES

Five mistakes to watch for.

1. Expecting "Fixes #N" to close an issue from a pull request into a release branch. Root cause: keywords in a pull request description are interpreted only when the pull request targets the default branch.
2. Editing a template on a feature branch and seeing no change. Root cause: issue templates and the pull request template are read from the default branch.
3. Deleting a large file in a new commit to make a rejected push succeed. Root cause: the limit applies to every object a push sends, and the file is still in history.
4. Keeping reviewed documentation in the wiki. Root cause: the wiki is a second repository, outside pull requests, rulesets, clones and mirrors of the code.
5. Reading a milestone named after a version as a release. Root cause: a milestone is a GitHub grouping toward a date; it names no commit.

## PRODUCTION EXAMPLE

**[ANIMATION]** decide: id=why nodes=q1:Did_the_pull_request_target_the_default_branch?|a:The_keyword_is_ignored:_nothing_closes|q2:Keyword_in_the_description_or_a_commit_message?|b:Closes_when_the_commit_reaches_the_default_branch|q3:Has_the_merge_happened_yet?|c:The_issue_closes_at_merge_time|d:The_issue_closes edges=q1>a:no|q1>q2:yes|q2>b:commit|q2>q3:PR|q3>c:no|q3>d:yes path=q1,a title=Fixes_#812,_and_the_issue_is_still_open at_level_1=50 at_level_2=72 at_level_3=4 at_level_4=68

**[ANIMATION]** step: level-2

Now, out of the lab. The team from the hook ships from release branches. After the incident with issue 812, they check the three causes in order. Did the pull request target the default branch? It didn't: cause found. Had it targeted `main`, two checks would remain.

**[ANIMATION]** step: level-4

Was the keyword in the pull request description, or only in a commit message? In that case the pull request isn't listed as linked, and the issue closes when the commit reaches the default branch. And had the merge happened yet? The issue closes at merge time.

**[ANIMATION]** step: path

Their fix is a process decision written down where contributors look. Teams that ship from release branches close issues by hand or by automation, and say so in `CONTRIBUTING.md`.

## PRACTICE EXERCISE

Your turn. Do Lab 19.1, "The practice organization and a repository with health files", in [`lab-manual/m19-github-platform.md`](../../lab-manual/m19-github-platform.md). Run it in your normal shell. Before each numbered step, write down what it will create in Git and what it will create on GitHub. Before you open the issue chooser, predict what it will offer.

The challenge is Exercise 19.7, "We made it private, so we are fine", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

## INTERVIEW QUESTION

Question 228 of the CTO question bank:

> "A pull request said "Fixes #812" and the issue is still open after the merge. Give three causes and how to tell them apart."

**[PAUSE]**

**[ANIMATION]** step: why.path

Answer out loud. A strong answer gives three distinct causes that follow from documented rules, not three guesses, and for each one the observation that confirms or excludes it. It says which layer holds the keyword and which layer acts on it. It ends with what a team that merges into non-default branches should do instead.

## RECAP

Let's land this.

You should now be able to say:

- An issue is a GitHub record; a closing keyword is text that GitHub acts on at merge time, for the default branch only.
- Projects plan, Discussions host open-ended questions, a wiki is a separate repository, and a package belongs to an account, not to a repository.
- Health files and templates are tracked files in well-known locations, read from the default branch.
- Each file of the standard layout has a reader and a mistake it prevents.
- Limits are enforced, recommended or display limits; the 100 MiB file limit applies to history, not to the working tree.

## HOMEWORK

Read sections 15.8 to 15.11, 15.13 to 15.15 and 15.19 of [Chapter 15](../../textbook/ch15-github.md). Do Exercise 19.6, "Health files and the issue chooser", in [`exercises/m19-m25-github.md`](../../exercises/m19-m25-github.md).

**[ANIMATION]** step: health.7

That was a long tour, and at every stop you can now say which layer you're standing on. Practise on one page of a repository you use. Next time, authentication: who you are, what you may do, and how Git asks for a credential. Until then, look at the state first and type second. See you in the next one.
