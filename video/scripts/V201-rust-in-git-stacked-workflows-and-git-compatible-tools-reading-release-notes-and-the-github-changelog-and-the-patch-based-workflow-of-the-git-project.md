# V201: Rust in Git, stacked workflows and Git-compatible tools, reading release notes and the GitHub Changelog, and the patch-based workflow of the Git project

- **Part.** 11, Expert: the frontier
- **Module.** 42
- **Planned minutes.** 24
- **Prerequisites.** V021, V200
- **Textbook sections.** [Chapter 14D](../../textbook/ch14d-frontier.md), sections 14D.9 to 14D.14
- **Demo scripts.** `labs/ch14d/release-notes.sh` (snippets `01-where` to `04-breaking-changes`), `labs/ch14d/patch-series.sh` (snippets `01-format-patch` to `07-v2-series`), `labs/ch14d/lab-42-3-format-patch-am.sh` (snippets `01-format-patch`, `02-read`, `03-am`, `04-compare`)

## HOOK

**[ON SCREEN]** "A new Git release is out. Does anything in it change behavior for our team?"

Most engineers answer that question by reading a vendor's blog post. The post is readable, well illustrated, and selective. It tells you that something exists. It doesn't tell you what your pipeline will do on Monday.

**[ANIMATION]** cards: id=disk question=The_sources_are_already_on_your_disk cards=one_file_of_release_notes_per_version|one_document_of_planned_breaking_changes|a_manual_page_for_every_command:at_the_version_you_have_installed at_1=30 at_2=42 at_3=54

This course ends today, and after today nobody selects for you. The sources that do answer the question are already on your disk: one file of release notes per version, one document of planned breaking changes, and a manual page for every command at the version you have installed. The last skill of the course is reading them in a fixed order, in fifteen minutes. Hold on to the question on screen. Before the demo you'll have five steps that answer it.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair, one last time. This is the final video. It has two halves and one purpose: that you can follow Git's development from primary sources, without a tutorial in between.

The first half is about sources. What the build option about Rust tells you. Which tools around Git are worth knowing by name. How to read release notes, the BreakingChanges document and the GitHub Changelog, and what each is a source for.

The second half is the workflow by which Git itself is developed: commits sent as e-mail. A commit is one saved snapshot of a project, with a message and the names of the people behind it. You create a patch series with `git format-patch`, apply it with `git am`, and send a second version with a range-diff, a comparison of two versions of a series of commits. In videos 20 and 21 you learned that a commit has an author and a committer, and trailers. Today you see the workflow those two identities exist for.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Say what the build option about Rust tells you and what the BreakingChanges document promises.
2. Read a release's notes in a fixed order and decide what it changes for a team.
3. Follow the GitHub Changelog for dated platform changes.
4. Create a patch series with a cover letter, apply it with `git am`, and explain why author and committer then differ.
5. Send a second version of a series and show what changed with `git range-diff`.

## CONCEPT

**[ANIMATION]** gates: id=rust gates=Git_2.49:done:-:optional|Git_2.52:done:-:auto-detected_by_one_of_the_two_build_systems|Git_2.55:done:-:enabled_by_default_in_both|Git_3.0:wait:planned:mandatory,_unless_a_deferral title=Rust_in_Git,_the_milestones_in_BreakingChanges

**Rust in Git.** Rust is a programming language, and parts of Git are now written in it. BreakingChanges gives the milestones. Rust code entered Git as optional in 2.49. It was auto-detected by one of the two build systems in 2.52. It is enabled by default in both from 2.55. And it becomes mandatory in 3.0, unless the impact on distributions leads to a deferral. The long-term-support promise you heard in video 199 exists for platforms without a Rust toolchain.

For you as a user nothing changes except where the binary comes from. In video 199 the first transcript printed "rust: disabled". The reason is the distributor: Homebrew builds its Git 2.55.0 with `NO_RUST=1`, as the textbook read in the formula on 2 October 2026. So "enabled by default" is a statement about the build system, and each distributor decides. That is what the build option tells you: what your binary was built with, not what the project's default is.

**[ANIMATION]** end

**Stacked workflows.** A stack is a chain of small dependent branches, each reviewed on its own. In Git the tools are `git rebase --update-refs`, `git range-diff` for comparing versions, and now `git history`, whose default of moving all descendant branches fits a stack.

**GitHub, not Git.** Stacked pull requests entered public preview on GitHub on 30 July 2026, with a `gh stack` extension for the command line. That is described from the changelog and not exercised in this course.

**Tools worth knowing by name.** None is part of Git, and none is needed for this course.

**[ON SCREEN]** The table of section 14D.9.

| Tool | What it is | Relation to Git |
|---|---|---|
| Jujutsu (`jj`) | A version-control system with no index, automatic rebasing of descendants and conflicts that can be committed | stores its data in Git repositories; its README calls it experimental |
| Sapling | Meta's client with first-class stacks | Git-compatible client |
| git-branchless | Adds undo, a smart log and restacking | a set of commands on top of Git; self-described alpha |
| Graphite, GitButler | Commercial products for stacked changes and branch management | on top of Git and GitHub |
| libgit2, JGit, Gitoxide | Implementations of Git as libraries, in C, Java and Rust | what many IDEs, servers and tools use in place of the `git` program |

The last row is the one that matters for the 3.0 defaults. BreakingChanges names exactly these three libraries as the ones that must support reftable before it becomes the default. A tool built on a library reads your repository with that library's abilities, not with those of the `git` you installed.

**[ANIMATION]** cards: id=notes numbered=on question=One_file_per_release,_the_same_three_parts cards=UI,_Workflows_&_Features:read_it_completely|Performance,_Internal_Implementation,_Development_Support_etc.:search_it_for_your_commands|Fixes_since_the_previous_version:search_it_for_your_commands marks=1:ring

**[ANIMATION]** step: 3

**Release notes.** Every release has one file, on GitHub and on your disk. Each file has the same three parts. First "UI, Workflows & Features". Then "Performance, Internal Implementation, Development Support etc.". And last "Fixes since" the previous version.

**[ANIMATION]** step: marks

Read the first part completely: it is short and it is where behavior changes are. Search the rest for the commands you depend on. The style is terse, one bullet per topic, often without the option names. The procedure that works: find the bullet, open the manual page of that command at the new version, and try it in a sandbox.

**[ANIMATION]** end

One caution from the textbook: a notes file is not proof of a release. The tag list is.

**BreakingChanges.** Its headings are the whole structure: the procedure, the changes, the removals, and what will not be deprecated. Each item links to the mailing-list thread where it was decided.

**The other channels.** The maintainer's "What's cooking" messages list every topic in flight and its state, and Git Rev News summarizes the list monthly. Vendor posts, the highlight posts of GitHub and GitLab for each release, are readable and selective: use them to learn that something exists, and the primary text to learn what it does.

**[ANIMATION]** cards: id=quiz question=GitHub_changes_how_a_platform_feature_behaves._Where_is_that_written_first? cards=A,_in_Git's_release_notes|B,_in_the_GitHub_Changelog|C,_in_BreakingChanges marks=2:ok at_1=50 at_2=65 at_3=80

**[ANIMATION]** step: 3

Quick quiz. GitHub changes how one of its platform features behaves. Where is that written first: A, in Git's release notes, B, in the GitHub Changelog, or C, in BreakingChanges? Your answer?

**[PAUSE]**

**[ANIMATION]** step: marks

**GitHub, not Git: the Changelog.** The answer is B. The GitHub Changelog is the primary source for platform behavior, dated entry by entry. A feature there has a state, preview or generally available, and often a plan gate. Nothing in it describes the `git` program on your machine, and a Git release changes nothing on github.com until GitHub deploys it.

**[ANIMATION]** gates: id=routine gates=Read:done:-:the_first_section_of_the_notes|Search:done:-:for_your_team's_commands|Look:done:-:at_the_diff_of_BreakingChanges|Decide:done:-:whether_any_default_you_rely_on_is_named|Write_down:done:-:the_minimum_version_for_anything_new title=Fifteen_minutes_per_release

**A routine of fifteen minutes per release.** Here's the answer to the question from the opening. Five steps, and this order is the answer to today's interview question. Read the first section of the notes. Search for your team's commands. Look at the diff of BreakingChanges. Decide whether any default you rely on is named. Write down the minimum version for anything new you want to adopt.

**[ANIMATION]** end

**The patch-based workflow, in one sentence.** Git itself is developed by sending commits as e-mail: `git format-patch` turns commits into message files, reviewers answer on the list, and the maintainer applies accepted series with `git am`. No pull request is involved.

**[ANIMATION]** flow: id=patches actors=the_author,the_mailing_list,the_maintainer msgs=1>1:git_commit_-s|1>2:git_format-patch,_git_send-email|2>1:review|1>2:v2,_with_a_range-diff|2>3:an_accepted_series|3>3:git_am;_seen,_next,_master title=Commits_sent_as_e-mail

**Precisely.** A contribution starts on a topic branch. Each commit carries a `Signed-off-by` trailer, from `git commit -s`, by which the author certifies the right to submit it. A trailer is a labelled line at the end of a commit message. `git format-patch` writes one file per commit plus an optional cover letter, and `git send-email` posts them to the project's mailing list. GitGitGadget is a bridge that turns a pull request on GitHub into such a series. After review the author sends a complete new version, v2, v3, with a range-diff against the previous one. The maintainer queues topics on the branch `seen`, merges them to `next` for testing and then to `master`. And `maint` receives fixes for the last release.

**[ANIMATION]** walk: id=mail columns=in_the_patch_file,what_it_is rows=the_"From"_line_with_an_ID_and_a_fixed_date:marks_the_format|the_From,_Date_and_Subject_headers:author,_author_date_and_subject|the_message_body:the_message|three_dashes,_then_a_diffstat:ignored_on_application|the_diff:the_change mono=off title=A_patch_file_is_a_commit_in_mail_form

**A patch file is a commit in mail form.** The `From` line with an ID and a fixed date marks the format. The `From:`, `Date:` and `Subject:` headers become author, author date and subject. The message body follows, then three dashes, then a diffstat that is ignored on application, then the diff.

**[ANIMATION]** end

**Why author and committer differ after `git am`.** The author comes from the mail headers. The committer is the person who ran `git am`. The two identities of a commit exist for this workflow.

**[ANIMATION]** walk: id=names columns=in_the_patch_workflow,on_GitHub rows=the_cover_letter:the_pull_request|a_new_version:a_force-pushed_branch|a_range-diff:"compare",_a_weaker_range-diff mono=off title=The_same_ideas,_other_names at_header=50 at_1=72 at_2=80 at_3=88

**Where you will meet it.** In three places besides the Git project: the Linux kernel and other list-based projects, vendors who send fixes as patch files, and environments where two repositories cannot reach each other. `git am` also underlies `git rebase --apply`. On GitHub the same ideas have other names: the pull request is the cover letter, a force-pushed branch is a new version, and "compare" is a weaker range-diff.

**[ANIMATION]** end

**Two cautions from section 14D.13.** `git am` refuses to start when the index has changes. And `git apply` without `--index` or `--3way` patches working files only and creates no commit: it is a tool for trying a patch, not for integrating one.

## MENTAL MODEL

**[ANIMATION]** walk: id=law columns=a_document_about_a_law,for_Git rows=the_statute_itself:the_manual_page_at_your_version,_and_BreakingChanges|the_official_gazette:the_release_notes;_for_the_platform,_the_GitHub_Changelog|the_newspaper_article:the_vendor_post mono=off title=Statute,_gazette,_newspaper

Two pictures help. For the sources, think of three kinds of document about a law. The statute itself: the manual page at your version, and BreakingChanges. The official gazette, which says what changed in each edition: the release notes, and for the platform the GitHub Changelog. And the newspaper article about it: the vendor post. You read the newspaper to learn that there is a new law. You don't plead in court from the newspaper.

**[ANIMATION]** cards: id=dates question=A_Git_release_applies_to_you_when_the_binary_changes cards=on_your_machine|on_your_runner|in_your_IDE's_library at_1=40 at_2=52 at_3=64

Where the picture breaks: a statute applies when it is published. A Git release applies to you when the binary on your machine, on your runner and in your IDE's library changes, and those are three different dates.

**[ANIMATION]** walk: id=letter columns=the_letter,the_patch rows=the_envelope:who_wrote_it,_when,_and_what_it_is_about|the_letter:why|the_enclosure:the_change|the_register,_signed_by_the_recipient:the_committer|where_it_belongs_in_the_cabinet:nothing_in_the_envelope_says mono=off title=A_letter_with_an_enclosure

For the patch workflow, think of a letter with an enclosure. The envelope says who wrote it and when, and what it is about. The letter explains why. The enclosure is the change. The recipient who files it signs the register: that signature is the committer. Nothing in the envelope says where in the recipient's cabinet the paper belongs, which is why a patch gets a new commit ID wherever it is applied, and why the cover letter can carry a `base-commit` line.

**[ANIMATION]** end

Try it now, on paper. Thirty seconds. Write three headers of a patch file, `From:`, `Date:` and `Subject:`, and beside each, the part of the commit it becomes. Then say out loud what a commit has that the file doesn't.

**[PAUSE]**

## DIAGRAM

**[DIAGRAM]** A new drawing: a patch file with its parts labelled, and which parts become the commit. The content is the first patch of the demo.

```text
  From <commit ID> Mon Sep 17 00:00:00 2001      <- marks the format; the ID is the sender's commit, not yours
  From: Asha Rao <asha@example.com>              -> AUTHOR of the new commit
  Date: Mon, 7 Sep 2026 10:08:00 +0530           -> AUTHOR DATE
  Subject: [PATCH 1/2] tok: lowercase the ...    -> SUBJECT ("[PATCH 1/2]" is stripped by git am)

  (message body)                                 -> BODY of the message, with its trailers
  Signed-off-by: Asha Rao <asha@example.com>
  ---                                            <- everything below this line is not message
   tok.py | 2 +-                                 <- diffstat: for the reader; ignored on application
   1 file changed, 1 insertion(+), 1 deletion(-)

  diff --git a/tok.py b/tok.py                   -> the CHANGE, applied to the index and working tree
  ...
  --
  2.55.0                                         <- the Git version that wrote the file

  not in the file:   COMMITTER and COMMITTER DATE  = whoever runs git am, and when
                     PARENT                        = wherever it is applied
                     therefore: a new commit ID, the same patch ID
```

Check your paper against the drawing. The three headers become the author, the author date and the subject. Build the rest top to bottom, with an arrow for everything that becomes part of the commit, and end with the three things that are not in the file: the committer, the committer date and the parent. Those three are why the applied commit has a new ID.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14d/release-notes`. All commands are 🟢 SAFE: they read files that came with your Git installation.

**Where the notes are.**

```bash
ls "$(git --html-path)/RelNotes" | grep -c adoc
ls "$(git --html-path)/RelNotes" | grep "^2\.5[3-5]"
```

<!-- snippet: ch14d/release-notes/01-where -->
```text
$ ls "$(git --html-path)/RelNotes" | grep -c adoc
541
$ ls "$(git --html-path)/RelNotes" | grep "^2\.5[3-5]"
2.53.0.adoc
2.54.0.adoc
2.54.1.adoc
2.55.0.adoc
```
<!-- /snippet -->

Into the lab. `git --html-path` prints the documentation directory of your installation. 541 files of release notes. And look at the list: a file for 2.54.1 exists, and the course's research found no tag and no tarball for that version. A notes file is not proof of a release.

**The three parts.**

<!-- snippet: ch14d/release-notes/02-sections -->
```text
$ grep -n -B1 "^---" "$(git --html-path)/RelNotes/2.55.0.adoc" | grep -v -e "---" -e "^--$"
4-UI, Workflows & Features
82-Performance, Internal Implementation, Development Support etc.
236-Fixes since v2.54
```
<!-- /snippet -->

Line 4, line 82, line 236. The first part is under eighty lines. That's the part you read completely.

**Search for your commands.** Predict: what will the notes for 2.55 say about `git history`? Say it out loud.

**[PAUSE]**

```bash
grep -n -A1 -e "git history" -e "Rust support" -e "Hook scripts" "$(git --html-path)/RelNotes/2.55.0.adoc"
```

<!-- snippet: ch14d/release-notes/03-search -->
```text
# What did 2.55 say about the commands of this chapter?
$ grep -n -A1 -e "git history" -e "Rust support" -e "Hook scripts" "$(git --html-path)/RelNotes/2.55.0.adoc"
7: * Hook scripts defined via the configuration system can now be
8-   configured to run in parallel.
--
28: * "git history" learned "fixup" command.
29-
--
88: * Rust support is enabled by default (but still allows opting out) in
89-   some future version of Git.
```
<!-- /snippet -->

One bullet: "git history" learned "fixup" command. That is all. No options, no example. From there you go to the manual page and to a sandbox, as you did in video 200. Note the third hit: the wording about Rust in the installed notes is vaguer than the milestone in BreakingChanges. Which is why the course cites the installed copy when it can.

**BreakingChanges.**

```bash
grep -n "^==" "$(git --html-path)/BreakingChanges.adoc"
grep -n "planned release date" "$(git --html-path)/BreakingChanges.adoc"
```

<!-- snippet: ch14d/release-notes/04-breaking-changes -->
```text
$ grep -n "^==" "$(git --html-path)/BreakingChanges.adoc"
62:== Procedure
80:== Git 3.0
89:=== Changes
243:=== Removals
342:== Superseded features that will not be deprecated
$ grep -n "planned release date" "$(git --html-path)/BreakingChanges.adoc"
83:is no planned release date for this breaking version yet.
# One line per planned change of a default:
$ sed -n '/^=== Changes/,/^=== Removals/p' "$(git --html-path)/BreakingChanges.adoc" | grep '^\* ' | cut -c1-78
* The default hash function for new repositories will be changed from "sha1"
* The default storage format for references in newly created repositories will
* In new repositories, the default branch name will be `main`. We have been
* Git will require Rust as a mandatory part of the build process. While Git
* The default value of `safe.bareRepository` will change from `all` to
```
<!-- /snippet -->

The headings: Procedure, Git 3.0, Changes, Removals, and the superseded features that will not be deprecated. Line 83 is the sentence from video 199: there is no planned release date. And the last command prints one line per planned change of a default: five lines, the five rows of the table in video 199. You have now verified a whole video against a file on your own disk, in three commands.

**[TERMINAL]** Replay `labs/run ch14d/patch-series`. Asha has a branch with two signed-off commits and no push access to the maintainer's repository.

**Create the series.** 🟢 SAFE: `git format-patch` writes files.

```bash
git log --format='%h %an | %s' origin/main..casefold
git format-patch --cover-letter --base=origin/main -o ../outbox/v1 origin/main
```

<!-- snippet: ch14d/patch-series/01-format-patch -->
```text
$ cd contributor
$ git log --format='%h %an | %s' origin/main..casefold
4309e9b Asha Rao | README: document the lowercasing
0cddac1 Asha Rao | tok: lowercase the input before splitting
$ git format-patch --cover-letter --base=origin/main -o ../outbox/v1 origin/main
../outbox/v1/0000-cover-letter.patch
../outbox/v1/0001-tok-lowercase-the-input-before-splitting.patch
../outbox/v1/0002-README-document-the-lowercasing.patch
```
<!-- /snippet -->

Two commits, three files: a cover letter numbered zero, and one file per commit.

**Read a patch file.** This is the diagram.

<!-- snippet: ch14d/patch-series/02-patch-file -->
```text
$ cat ../outbox/v1/0001-tok-lowercase-the-input-before-splitting.patch
From 0cddac17b0e047370ed3799c71bf9c20fd534983 Mon Sep 17 00:00:00 2001
From: Asha Rao <asha@example.com>
Date: Mon, 7 Sep 2026 10:08:00 +0530
Subject: [PATCH 1/2] tok: lowercase the input before splitting

Signed-off-by: Asha Rao <asha@example.com>
---
 tok.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/tok.py b/tok.py
index 2800645..d89f8b7 100644
--- a/tok.py
+++ b/tok.py
@@ -1,2 +1,2 @@
 def tokenize(text):
-    return text.split()
+    return text.lower().split()
-- 
2.55.0
```
<!-- /snippet -->

Find each part: the `From` line with `0cddac1`, the author, the date, the subject with its `[PATCH 1/2]` prefix, the trailer, the three dashes, the diffstat, the diff.

<!-- snippet: ch14d/patch-series/03-cover-letter -->
```text
$ sed -n '/^Subject/,$p' ../outbox/v1/0000-cover-letter.patch
Subject: [PATCH 0/2] *** SUBJECT HERE ***

*** BLURB HERE ***

Asha Rao (2):
  tok: lowercase the input before splitting
  README: document the lowercasing

 README.md | 2 +-
 tok.py    | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)


base-commit: 9ba24bca99d4152c3fd1aff140540eb6cb16a88f
-- 
2.55.0
```
<!-- /snippet -->

The cover letter is a template to fill in: a subject and a blurb in capitals between asterisks. Below it, the list of commits and the overall diffstat. And `base-commit`: the commit the series applies to, which tells reviewers and tools where to put it.

**Apply it.** The maintainer, in a repository that has never seen the branch. 🟡 CAUTION: `git am` creates new commits on the current branch. Preview: `git apply --check`. Recovery: `git am --abort` while it is stopped. Afterwards, the reflog of the branch. Predict the author and the committer of the applied commits. Say it out loud.

**[PAUSE]**

```bash
git switch -q -c review/casefold
git am ../outbox/v1/0001-*.patch ../outbox/v1/0002-*.patch
git log --format='%h author: %an, committer: %cn | %s' -2
git log -1 --format=%B
```

<!-- snippet: ch14d/patch-series/04-am -->
```text
# The maintainer, in a repository that has never seen the branch:
$ cd ../upstream
$ git switch -q -c review/casefold
$ git am ../outbox/v1/0001-*.patch ../outbox/v1/0002-*.patch
Applying: tok: lowercase the input before splitting
Applying: README: document the lowercasing
$ git log --format='%h author: %an, committer: %cn | %s' -2
632b3e7 author: Asha Rao, committer: Ravi Menon | README: document the lowercasing
463b82b author: Asha Rao, committer: Ravi Menon | tok: lowercase the input before splitting
$ git log -1 --format=%B
README: document the lowercasing

Signed-off-by: Asha Rao <asha@example.com>
```
<!-- /snippet -->

Author: Asha Rao. Committer: Ravi Menon, the person who ran `git am`. The sign-off trailer travelled in the message. This is what the two identities of video 20 are for.

**Same change, new ID.**

```bash
git rev-parse 'HEAD^{tree}'
git -C ../contributor rev-parse 'casefold^{tree}'
git show HEAD~1 | git patch-id --stable | cut -d" " -f1
git -C ../contributor show casefold~1 | git patch-id --stable | cut -d" " -f1
```

<!-- snippet: ch14d/patch-series/05-same-change-new-id -->
```text
# The applied commits have new IDs and the same content as the originals:
$ git rev-parse 'HEAD^{tree}'
95b752c13b6b8cd0443d6e6cc40521f652ffafe6
$ git -C ../contributor rev-parse 'casefold^{tree}'
95b752c13b6b8cd0443d6e6cc40521f652ffafe6
$ git show HEAD~1 | git patch-id --stable | cut -d" " -f1
20e1452a5c438e93046c3c9fcf204de5c866748a
$ git -C ../contributor show casefold~1 | git patch-id --stable | cut -d" " -f1
20e1452a5c438e93046c3c9fcf204de5c866748a
```
<!-- /snippet -->

Equal trees, equal patch IDs, different commit IDs. A patch ID is computed from the change alone. The content arrived intact. The committer, the committer date and the parent are new.

**[ANIMATION]** graph: id=v2 9ba24bc-0cddac1-4309e9b casefold; 9ba24bc origin/main; HEAD=casefold => + 4309e9b casefold-v1; 9ba24bc-3e0656d-5b37458 casefold; cmd:git_branch_casefold-v1; say:Version_1_kept,_two_new_commits_for_version_2 title=Version_1_kept,_version_2_rewritten at_state_2=15

**[ANIMATION]** step: state-1

**Version 2.** Review asked for `casefold()` instead of `lower()`. This is the contributor's branch as it was sent.

**[ANIMATION]** step: state-2

The contributor keeps version 1 under another name, `casefold-v1`, and rewrites the branch: two new commits, and `casefold` now points at them.

```bash
git branch casefold-v1
git range-diff origin/main casefold-v1 casefold
```

<!-- snippet: ch14d/patch-series/06-v2 -->
```text
# Review asked for casefold() instead of lower(). The contributor keeps v1 and rewrites the branch:
$ cd ../contributor
$ git branch casefold-v1
$ git range-diff origin/main casefold-v1 casefold
1:  0cddac1 < -:  ------- tok: lowercase the input before splitting
-:  ------- > 1:  3e0656d tok: lowercase the input before splitting
2:  4309e9b = 2:  5b37458 README: document the lowercasing
```
<!-- /snippet -->

On its own, `git range-diff` judged the rewritten first patch a total rewrite and printed it as removed and added. Its creation factor defaults to 60, and in a two-line patch one changed line is a large share. The second patch is marked equal.

```bash
git format-patch -v2 --cover-letter --range-diff=casefold-v1 --base=origin/main -o ../outbox/v2 origin/main
sed -n '/^Range-diff/,/^-- /p' ../outbox/v2/v2-0000-cover-letter.patch
```

<!-- snippet: ch14d/patch-series/07-v2-series -->
```text
$ git format-patch -v2 --cover-letter --range-diff=casefold-v1 --base=origin/main -o ../outbox/v2 origin/main
../outbox/v2/v2-0000-cover-letter.patch
../outbox/v2/v2-0001-tok-lowercase-the-input-before-splitting.patch
../outbox/v2/v2-0002-README-document-the-lowercasing.patch
$ sed -n '/^Range-diff/,/^-- /p' ../outbox/v2/v2-0000-cover-letter.patch
Range-diff against v1:
1:  0cddac1 ! 1:  3e0656d tok: lowercase the input before splitting
    @@ tok.py
     @@
      def tokenize(text):
     -    return text.split()
    -+    return text.lower().split()
    ++    return text.casefold().split()
2:  4309e9b = 2:  5b37458 README: document the lowercasing

base-commit: 9ba24bca99d4152c3fd1aff140540eb6cb16a88f
-- 
```
<!-- /snippet -->

The files carry `v2` in their names. And the cover letter now contains a section "Range-diff against v1". `format-patch --range-diff` uses a much higher creation factor, because it compares iterations of one topic, so the same pair appears with an exclamation mark and a diff of the two diffs: `lower()` became `casefold()`. This is how a reviewer of version 2 sees what changed since version 1 without reading everything again.

**[TERMINAL]** The round trip as you will do it in the lab. Replay `labs/run ch14d/lab-42-3-format-patch-am`, the first four snippets. Its failure scenario, a patch that no longer applies, is yours.

<!-- snippet: ch14d/lab-42-3-format-patch-am/01-format-patch -->
```text
$ cd fork
$ git log --oneline origin/main..fix/casefold
92eba7f README: document the casefolding
41a7b91 tok: casefold the input before splitting
$ git format-patch -o ../outbox origin/main
../outbox/0001-tok-casefold-the-input-before-splitting.patch
../outbox/0002-README-document-the-casefolding.patch
```
<!-- /snippet -->

<!-- snippet: ch14d/lab-42-3-format-patch-am/02-read -->
```text
$ sed -n '1,8p' ../outbox/0001-tok-casefold-the-input-before-splitting.patch
From 41a7b91d3ea89ca2dd95e80c5a999b4db206795d Mon Sep 17 00:00:00 2001
From: Lab User <you@example.com>
Date: Mon, 7 Sep 2026 10:07:00 +0530
Subject: [PATCH 1/2] tok: casefold the input before splitting

---
 tok.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git apply --stat ../outbox/*.patch
 tok.py |    2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
 README.md |    2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
<!-- /snippet -->

Read before you apply: the first lines of the patch, and `git apply --stat` for what the files would touch. Both are 🟢.

<!-- snippet: ch14d/lab-42-3-format-patch-am/03-am -->
```text
$ cd ../upstream
$ git apply --check ../outbox/0001-tok-casefold-the-input-before-splitting.patch
[exit status: 0]
$ git switch -q -c review/casefold
$ git am ../outbox/*.patch
Applying: tok: casefold the input before splitting
Applying: README: document the casefolding
$ git log --format='%h author: %an, committer: %cn | %s'
25c29be author: Lab User, committer: Ravi Menon | README: document the casefolding
6c00e59 author: Lab User, committer: Ravi Menon | tok: casefold the input before splitting
9ba24bc author: Ravi Menon, committer: Ravi Menon | Add whitespace tokenizer
```
<!-- /snippet -->

`git apply --check` exits 0: the patch would apply. Then `git am`, and the log shows the pattern again: author from the patch, committer the person who applied it.

<!-- snippet: ch14d/lab-42-3-format-patch-am/04-compare -->
```text
$ git rev-parse 'review/casefold^{tree}'
f5e5887e65c78cdcb402af517b9d66e542afa85d
$ git -C ../fork rev-parse 'fix/casefold^{tree}'
f5e5887e65c78cdcb402af517b9d66e542afa85d
$ git rev-parse --short review/casefold
25c29be
$ git -C ../fork rev-parse --short fix/casefold
92eba7f
```
<!-- /snippet -->

The two trees are equal, and the two commit IDs are not: `25c29be` here, `92eba7f` in the fork. Same content, different commit. You could have predicted every line of this output from the diagram.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Deciding from a vendor post.** Root cause: highlight posts are selective, so they show that something exists and not what it changes for your commands and defaults.
2. **Reading "enabled by default" as "enabled in my binary".** Root cause: the default belongs to the build system, and each distributor decides how it builds.
3. **Looking for Git behavior in the GitHub Changelog, or the reverse.** Root cause: the Changelog is the primary source for the platform only, and a Git release changes nothing on github.com until GitHub deploys it.
4. **Expecting an applied patch to keep its commit ID.** Root cause: committer, committer date and parent are not in the patch file, so the applied commit is a new object with the same patch ID.
5. **Integrating with `git apply`.** Root cause: without `--index` or `--3way` it patches working files only and creates no commit, and it carries no author or message.

## PRODUCTION EXAMPLE

Now, out of the lab. A platform team upgrades Git on its build images twice a year. The engineer who owns the upgrade has a routine, and it takes her a quarter of an hour per release.

**[ANIMATION]** replay: routine

She opens the notes file of each new version on her disk and reads the first section completely. She searches all three sections for the commands in the team's release scripts. She compares the BreakingChanges document with the copy from the previous upgrade. She checks whether any default the team relies on is named. And she writes down, in the upgrade ticket, the minimum version for anything new the team wants to use. For platform changes she reads the GitHub Changelog separately, by date, and notes for each entry its state and its plan gate.

**[ANIMATION]** end

The same week a vendor sends a fix for a tokenizer library as two patch files, because the vendor cannot reach the team's repository. She reads the files, runs `git apply --check`, applies them with `git am` on a review branch, and opens a pull request from it. The commits show the vendor's engineer as author and her as committer, and the team's history says truthfully who wrote the fix and who applied it. When the vendor sends a second version, she asks for it with a range-diff, and reviews the difference between the two versions in a minute.

## PRACTICE EXERCISE

Your turn. Do Lab 42.3, "A format-patch and am round trip", in [`lab-manual/m42-frontier.md`](../../lab-manual/m42-frontier.md).

Before you apply the patches, predict for the applied commits: the author, the committer, whether the tree will equal the original's, and whether the commit ID will. Before the lab's failure scenario, predict what `git am` will do when the base has moved, what state it will leave behind, and which of its exits you know from the way video 182 thinks about operations in progress.

The challenge: read the release notes of the Git version after the one installed, and write, for your team, one paragraph: what changes, whom it affects, what to do.

## INTERVIEW QUESTION

**[ON SCREEN]** Q439: "How do you find out whether a behavior change in a new Git release affects your team? Which documents do you read, in which order?"

Read the question, then answer out loud.

**[PAUSE]**

This is the last question of the course, and it asks for a procedure. A strong answer names the documents by what each is a source for, primary before secondary, and gives an order with a reason for the order. It says where the documents are, so that the answer doesn't depend on a website. It includes the step that turns reading into knowledge: the manual page at the new version, and a sandbox. It separates the `git` program from the platform and names the platform's own primary source. And it ends on a limit: which of your tools doesn't use the `git` program at all, and so won't change when you upgrade it.

## RECAP

Let's land this, for the last time.

- The Rust line of `git version --build-options` describes your binary; the project's milestones and promises are in BreakingChanges.
- Release notes have three parts; read the first completely, search the rest for your commands, then go to the manual page and a sandbox.
- BreakingChanges is the source for planned changes and removals; the GitHub Changelog is the source for dated platform changes; vendor posts tell you that something exists.
- A patch file is a commit in mail form: `git format-patch` writes it, `git am` applies it, the author comes from the file and the committer is whoever applied it.
- A new version of a series is sent whole, with a range-diff that shows what changed since the previous one.

## HOMEWORK

Read sections 14D.9 to 14D.14 and do the Practice section, 14D.16, with its two drills. Read [`reference/references.md`](../../reference/references.md): it is the list of primary sources behind this course, and from today it is your reading list.

That's the end of the course. You began with a repository read file by file. You can now investigate a Git or GitHub problem from first principles, explain the root cause with its layer, choose the lowest-risk fix, verify it, prevent its recurrence, and find out for yourself what the next release changes.

**[ANIMATION]** cards: id=keep question=Yours_to_keep cards=the_references_file:your_reading_list|the_glossary:when_you_want_to_be_exact_about_a_word|your_playbook_and_your_weak-area_tracker:yours_to_keep_up_to_date|the_labs_and_the_incidents:generated_afresh_whenever_you_want_the_practice|a_new_Git_release:fifteen_minutes_with_its_notes

So what now? Keep the course materials working for you. The references file is your reading list. The glossary is there whenever a colleague or an error message uses a word you want to be exact about. Your playbook and your weak-area tracker are yours to keep up to date. The labs and the incidents can be generated afresh whenever you want the practice. And when a new Git release comes out, take your fifteen minutes with its notes.

**[ANIMATION]** end

Thank you for working through all of this with such care. It has been a pleasure to teach you. Look at the state first, type second, and goodbye for now.
