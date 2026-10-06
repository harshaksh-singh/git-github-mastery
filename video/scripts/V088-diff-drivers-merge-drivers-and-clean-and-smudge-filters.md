# V088: Diff drivers, merge drivers, and clean and smudge filters

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 14, Worktrees, attributes, hooks, stash internals, rerere
- **Planned minutes.** 26
- **Prerequisites.** V087
- **Textbook sections.** [Chapter 14C](../../textbook/ch14c-stash-rerere-attributes-hooks.md), sections 14C.6 to 14C.8
- **Demo scripts.** `labs/ch14c/attr-diff.sh`, `labs/ch14c/attr-merge.sh`, `labs/ch14c/attr-filter.sh`

## HOOK

**[ON SCREEN]** "We committed a `.gitattributes` that strips notebook outputs. A new hire's first commit contains 40 MB of outputs. Why did the rule not apply to her?"

The team did the careful thing. They wrote a filter that removes outputs from notebooks on the way into the repository. A notebook is a document that keeps code together with its results. They committed the attribute line. They tested it. For six months no output reached history.

Then a new engineer cloned the repository, ran a notebook, and committed. Her clone had the attribute. `git check-attr` in her clone names the filter. And Git said nothing at all while it stored 40 megabytes of rendered plots.

The rule did apply to her. The rule says "use the filter named nbstrip". Her machine had no filter of that name, and Git treats that as "no filter", without a warning. She did nothing wrong.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the last video `.gitattributes` named properties that every Git understands: `text`, `eol`, `export-ignore`. Today it names programs. There are three places where Git lets a program of yours take part: when it shows a change, when it merges a file, and when content moves between the working tree and the repository.

For all three, the same rule holds, and it's the rule that explains the hook. The name is in a versioned file and reaches every clone. The definition is in configuration and reaches nobody. One question to keep for later: would marking the filter as required have saved the new hire?

The third mechanism, the filter, is also the foundation of two things later in this course: Git LFS, and notebook stripping in the AI and ML part.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- make a binary or generated format diffable with a `textconv` driver;
- choose `merge=union`, `-merge` or a custom merge driver for a file and state the risk of each;
- write a clean and smudge filter pair and show what is stored and what is checked out;
- explain what a clone receives of a filter and what `required` changes;
- name where this mechanism is used later in the course.

## CONCEPT

**Diff drivers.** In one sentence: the `diff` attribute tells Git how to show changes to a path. Not at all, with `-diff`. With a named built-in pattern set for hunk headers, such as `diff=python`. Or through a driver that you define in configuration, of which `textconv` is the most useful kind.

**[ANIMATION]** flow: id=textconv actors=git_diff,*your_textconv_program subs=git_show,_git_log_-p|defined_in_configuration msgs=1>2:a_temporary_file,_one_per_version|2>1:a_text_rendering_of_it|1>1:diffs_the_two_renderings|1>1:what_is_stored_does_not_change title=A_textconv_driver_changes_what_is_displayed

A `textconv` program receives the name of a temporary file and prints a text rendering of it. Git then diffs the renderings. The conversion is one-way and meant for people. `git diff`, `git show` and `git log -p` use it. `git format-patch` never does, because a patch made from converted text could not be applied. A diff driver changes what is displayed, never what is stored.

**[ANIMATION]** walk: id=choices columns=merge_attribute,when_both_sides_changed_the_file,the_risk rows=(not_set):the_normal_three-way_text_merge:-|-merge:refuses_to_merge_by_content:a_conflict_every_time|merge=union:keeps_the_lines_of_both_sides:a_wrong_file,_no_conflict|merge=<your_name>:runs_a_command_of_your_own:keep-ours_discards_the_other_side marks=2.3:wait,3.3:bad,4.3:bad title=Four_choices_for_one_path mono=off

**Merge drivers.** In one sentence: the `merge` attribute chooses the file-level merge for a path when both sides changed it. There are four choices. The normal three-way text merge, which combines two versions against their common base. A refusal to merge by content, `-merge`. The built-in `union` driver, which keeps the lines of both sides. Or a command of your own.

**[ANIMATION]** flow: id=driver actors=Git,*your_merge_driver subs=-|merge.<name>.driver msgs=1>2:%O_base,_%A_current_branch,_%B_other_branch|2>2:leaves_the_result_in_%A|2>1:exit_status_0,_a_clean_merge:ok|2>1:exit_status_1_to_128,_a_conflict:fail title=A_custom_merge_driver mono=on at_1=15 at_2=45 at_3=60 at_4=75

A custom driver is a configuration section with a `driver` command line. Git calls it with temporary files for the three versions: `%O` for the base, `%A` for the current branch, `%B` for the other branch. The driver leaves the result in `%A` and exits with status 0 for a clean merge, or 1 to 128 for a conflict. The attribute applies to merges, cherry-picks, reverts and rebases alike.

**[ANIMATION]** step: choices.4

**[ANIMATION]** say: union_and_a_keep-ours_driver_can_give_a_wrong_file_without_a_conflict

The risks. The manual warns that `union` "tends to leave the added lines in the resulting file in random order", and it keeps both versions of a line that both sides edited. So it can produce a wrong file without a conflict. A keep-ours driver silently discards the other side. And `-merge` gives you a conflict every time, which for some files is the honest answer.

**[ANIMATION]** trees: file=eda.ipynb steps=setup,add,commit names=Working_tree,Index,Repository subs=the_file_you_run,what_git_add_stages,what_the_blob_holds chips=with_outputs,with_outputs,with_outputs versions=with_outputs,no_outputs,no_outputs history=off id=clean title=A_clean_filter,_defined_in_this_clone cmd_add=git_add_--renormalize_. say_setup=The_notebook_was_committed_with_its_outputs,_before_the_filter_existed say_add=clean_runs_at_git_add:_the_index_gets_the_notebook_without_outputs say_commit=The_blob_holds_the_cleaned_form._The_file_on_disk_still_has_its_outputs.

**[ANIMATION]** step: commit

**Filters.** In one sentence: a filter driver is a pair of commands. `clean` rewrites a file's content on its way from the working tree into the repository, at `git add`. `smudge` rewrites it on its way from the repository into the working tree, at checkout. The blob, the stored bytes of the file, holds the cleaned form.

Each command reads the content on standard input and writes the converted content to standard output. Either half may be missing. A clean filter should be idempotent: cleaning cleaned content changes nothing. On the way in, the filter runs before the line-ending conversion. On the way out, after it.

**[ANIMATION]** end

The manual distinguishes two purposes. Convenience filters make content nicer, and the project stays usable without them. Every filter is of this kind by default.

**[ANIMATION]** trees: file=eda.ipynb steps=setup,add,commit names=Working_tree,Index,Repository subs=she_ran_the_notebook,what_git_add_stages,what_the_blob_holds chips=with_outputs,no_outputs,no_outputs versions=no_outputs,with_outputs,with_outputs history=off id=nofilter title=The_same_attribute,_in_a_clone_without_the_definition cmd_add=off cmd_commit=git_commit_-am say_setup=Her_clone_has_the_attribute_line._It_has_no_filter.nbstrip.clean. say_add=No_definition,_no_filter:_the_content_passes_through_unchanged say_commit=The_outputs_are_in_history._Git_printed_no_message.

**[ANIMATION]** step: commit

In the manual's words, "a missing filter driver definition in the config, or a filter driver that exits with a non-zero status, is not an error but makes the filter a no-op passthru." That's the new hire's clone, on screen.

**[ANIMATION]** end

Required filters turn stored content that is unusable by itself, a pointer or ciphertext, into the real thing. With `filter.<name>.required = true`, a failing filter becomes an error. Git LFS is the best-known example.

**[ANIMATION]** stores: id=line title=The_name_travels,_the_definition_does_not mono=on boxes=*.gitattributes:a_tracked_file,_reaches_every_clone|.git/config:local,_reaches_nobody rows=1:A:*.ipynb_filter=nbstrip|1:B:[filter_"nbstrip"]_clean_=_...|2:B:required_=_true@hl arrows=1:A1>B1:names at_1=20

**[ANIMATION]** step: 1

Why doesn't Git let the repository define the commands? Because that would let anyone whose repository you clone run programs on your machine. The line between "versioned" and "local" is a security boundary.

**[ANIMATION]** end

When not to use these. A `textconv` program runs with your permissions on every diff of a matching file, and a rendering hides what it leaves out. A custom merge driver exists only in the clones that defined it, and merges for a pull request run on GitHub's servers, where your driver configuration doesn't exist. And a filter changes the meaning of "clean working tree": it now means "cleans to what is committed".

## MENTAL MODEL

**[ANIMATION]** step: clean.commit

**[ANIMATION]** say: Repacked_on_the_way_in,_unpacked_on_the_way_out

The textbook's analogy for a filter: a customs desk between your files and the object database. Goods are repacked on the way in and unpacked on the way out.

**[ANIMATION]** step: nofilter.commit

Where it breaks: every traveller brings a desk of their own, or none. There is no shared customs office. A traveller without a desk walks straight through, and nobody stops them.

**[ANIMATION]** end

For all three drivers, keep the folder labels from the last video. The label "show through viewer X" is in the cabinet for everyone to read. Viewer X is a program on one person's desk. And the last video's warning now has consequences: a missing viewer produces no complaint.

## DIAGRAM

Try it now, on paper. Two columns: travels with a clone, or stays on this machine. Place three things: the attribute line, the clean command, and `required = true`. Pause me for thirty seconds and write your answer.

**[PAUSE]**

**[DIAGRAM]** The picture of section 14C.8. Draw the two boxes and the two arrows, then the two lines underneath.

```text
   working tree                                   repository (index, then commit)
   +---------------------+      clean (git add)     +----------------------+
   | eda.ipynb           |  --------------------->  | blob: no outputs     |
   | with outputs        |                          |                      |
   |                     |  <---------------------  |                      |
   +---------------------+   smudge (checkout)      +----------------------+
        .gitattributes: "*.ipynb filter=nbstrip"         travels with clone
        .git/config:    [filter "nbstrip"] clean = ...   stays on this machine
```

The two lines at the bottom are the whole lesson. The first line is in a tracked file. The second is in `.git/config`.

**[ON SCREEN]** The rule for all three kinds of driver, from section 14C.8.

| | Named in (versioned) | Defined in (local) | In a clone without the definition |
|---|---|---|---|
| Diff driver | `diff=<name>` | `diff.<name>.textconv`, `.command`, `.xfuncname` | default diff, no message |
| Merge driver | `merge=<name>` | `merge.<name>.driver` | default text merge, no message |
| Filter, convenience | `filter=<name>` | `filter.<name>.clean`, `.smudge` | content passes through unchanged, no message |
| Filter, required | `filter=<name>` | the same, plus `filter.<name>.required = true` | still passes through: `required` is part of the missing definition |

The last row surprises people. `required` protects against a filter that is defined and fails. It doesn't protect against a clone that never defined it. So the answer to the question from the start is no: `required` would not have saved the new hire.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14c/attr-diff`. A notebook was run again after one cell was edited.

```bash
git diff --stat
git diff eda.ipynb
```

<!-- snippet: ch14c/attr-diff/01-raw-diff -->
```text
$ git diff --stat
 eda.ipynb | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
$ git diff eda.ipynb
diff --git a/eda.ipynb b/eda.ipynb
index 41de20e..e0025c4 100644
--- a/eda.ipynb
+++ b/eda.ipynb
@@ -9,19 +9,19 @@
   },
   {
    "cell_type": "code",
-   "execution_count": 7,
+   "execution_count": 9,
    "metadata": {},
    "outputs": [
     {
      "name": "stdout",
      "output_type": "stream",
      "text": [
-      "accuracy 0.81\n"
+      "accuracy 0.84\n"
      ]
     }
    ],
    "source": [
-    "print('accuracy', evaluate(model))"
+    "print('accuracy', evaluate(model, split='test'))"
    ]
   }
  ],
```
<!-- /snippet -->

Three changed lines, of which one matters: the edit is mixed with a new execution count and new output. Name a driver in `.gitattributes`, and predict whether the diff changes. Say it out loud. I'll wait.

**[PAUSE]**

```bash
printf '*.ipynb diff=notebook\n' > .gitattributes
git check-attr diff -- eda.ipynb
git diff --stat eda.ipynb
```

<!-- snippet: ch14c/attr-diff/02-attribute-only -->
```text
$ printf '*.ipynb diff=notebook\n' > .gitattributes
$ git check-attr diff -- eda.ipynb
eda.ipynb: diff: notebook
# The attribute names a driver that no configuration defines yet, so nothing changes:
$ git diff --stat eda.ipynb
 eda.ipynb | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
```
<!-- /snippet -->

`git check-attr` reports the attribute, and the diff is unchanged. An attribute that names an undefined driver has no effect and causes no message. That is row one of the table, seen live. Now define the driver. 🟡 CAUTION: `git config set diff.<name>.textconv` decides which program Git runs on your machine.

<!-- snippet: ch14c/attr-diff/03-driver -->
```text
$ cat tools/nbsource.py
#!/usr/bin/env python3
"""textconv for notebooks: print only the source of each cell."""
import json
import sys

nb = json.load(open(sys.argv[1], encoding="utf-8"))
for n, cell in enumerate(nb["cells"], 1):
    print(f"# cell {n} ({cell['cell_type']})")
    print("".join(cell["source"]))
$ git config set diff.notebook.textconv 'python3 tools/nbsource.py'
$ git diff eda.ipynb
diff --git a/eda.ipynb b/eda.ipynb
index 41de20e..e0025c4 100644
--- a/eda.ipynb
+++ b/eda.ipynb
@@ -1,4 +1,4 @@
 # cell 1 (markdown)
 # Error analysis
 # cell 2 (code)
-print('accuracy', evaluate(model))
+print('accuracy', evaluate(model, split='test'))
```
<!-- /snippet -->

The program prints only the source of each cell. With it configured, the header of the diff still names `eda.ipynb` and the real blob IDs. The body is the difference between the two renderings: one line of code.

```bash
git diff --no-textconv --stat eda.ipynb
git log -1 -p --format=%s -- eda.ipynb
```

<!-- snippet: ch14c/attr-diff/04-scope -->
```text
# textconv is for reading. Commands that produce patches for machines ignore it:
$ git diff --no-textconv --stat eda.ipynb
 eda.ipynb | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
$ git add . && git commit -q -m "Evaluate on the test split"
$ git log -1 -p --format=%s -- eda.ipynb
Evaluate on the test split

diff --git a/eda.ipynb b/eda.ipynb
index 41de20e..e0025c4 100644
--- a/eda.ipynb
+++ b/eda.ipynb
@@ -1,4 +1,4 @@
 # cell 1 (markdown)
 # Error analysis
 # cell 2 (code)
-print('accuracy', evaluate(model))
+print('accuracy', evaluate(model, split='test'))
$ git format-patch -1 --stdout -- eda.ipynb | grep -c "execution_count"
2
```
<!-- /snippet -->

`--no-textconv` switches the conversion off. `git log -p` uses it. And the patch that `format-patch` writes, at the end of the snippet, contains the raw JSON. A textconv is for reading.

Hunk headers need no configuration, only the attribute.

```bash
git diff metrics.py
```

<!-- snippet: ch14c/attr-diff/05-funcname -->
```text
$ git diff metrics.py
diff --git a/metrics.py b/metrics.py
index 75ceae5..7bfb222 100644
--- a/metrics.py
+++ b/metrics.py
@@ -5,7 +5,7 @@ class Accuracy:
         if gold is None:
             return
         self.pairs.append((pred, gold))
-        self.hits += int(pred == gold)
+        self.hits += int(pred.strip() == gold.strip())
 
     def result(self):
         return self.hits / self.total
$ printf '*.py diff=python\n' >> .gitattributes
$ git diff metrics.py
diff --git a/metrics.py b/metrics.py
index 75ceae5..7bfb222 100644
--- a/metrics.py
+++ b/metrics.py
@@ -5,7 +5,7 @@ def update(self, pred, gold):
         if gold is None:
             return
         self.pairs.append((pred, gold))
-        self.hits += int(pred == gold)
+        self.hits += int(pred.strip() == gold.strip())
 
     def result(self):
         return self.hits / self.total
```
<!-- /snippet -->

The first header says `class Accuracy:`. After the attribute `diff=python` is added, the second says `def update(self, pred, gold):`. The manual lists built-in pattern sets for python, java, golang, rust, markdown, bash and about twenty more. This is also what `git log -L` with a function name relies on.

**[TERMINAL]** Replay `labs/run ch14c/attr-merge`. Both branches appended a line to `CHANGELOG.md` and a dependency to `requirements.lock`.

```bash
git merge feat/cache
git merge --abort
```

<!-- snippet: ch14c/attr-merge/01-two-conflicts -->
```text
$ git merge feat/cache
Auto-merging CHANGELOG.md
CONFLICT (content): Merge conflict in CHANGELOG.md
Auto-merging requirements.lock
CONFLICT (content): Merge conflict in requirements.lock
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git merge --abort
```
<!-- /snippet -->

Two conflicts of a kind that returns at every merge. Add two attributes: one names a built-in driver, the other a driver of your own that doesn't exist yet. Quick quiz: which file still conflicts? The changelog, the lock file, or both. Say it out loud.

**[PAUSE]**

```bash
printf 'CHANGELOG.md      merge=union\nrequirements.lock merge=keep-ours\n' > .gitattributes
git add .gitattributes && git commit -q -m "Add merge attributes"
git merge feat/cache
git status -s
```

<!-- snippet: ch14c/attr-merge/02-attributes -->
```text
$ printf 'CHANGELOG.md      merge=union\nrequirements.lock merge=keep-ours\n' > .gitattributes
$ git add .gitattributes && git commit -q -m "Add merge attributes"
$ git merge feat/cache
Auto-merging CHANGELOG.md
Auto-merging requirements.lock
CONFLICT (content): Merge conflict in requirements.lock
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status -s
M  CHANGELOG.md
UU requirements.lock
$ cat CHANGELOG.md
# Changelog

- Add retrieval endpoint
- Add rate limiting
- Cache embeddings on disk
$ git merge --abort
```
<!-- /snippet -->

The lock file. `union` merged the changelog: both new lines are there. The lock file still conflicts, because `merge=keep-ours` names an undefined driver, and Git fell back to the text merge without a word. Row two of the table. Define it.

```bash
git config set merge.keep-ours.name 'keep our version of generated files'
git config set merge.keep-ours.driver true
git merge feat/cache
```

<!-- snippet: ch14c/attr-merge/03-driver -->
```text
# A merge driver is a command that leaves its result in %A and reports success with exit status 0.
# "true" changes nothing, so the version of the current branch stays:
$ git config set merge.keep-ours.name 'keep our version of generated files'
$ git config set merge.keep-ours.driver true
$ git merge feat/cache
Auto-merging CHANGELOG.md
Auto-merging requirements.lock
Merge made by the 'ort' strategy.
 CHANGELOG.md | 1 +
 1 file changed, 1 insertion(+)
[exit status: 0]
$ cat requirements.lock
torch==2.4.0
limits==3.13.0
$ git show --stat --format=%s HEAD
Merge branch 'feat/cache'

 CHANGELOG.md | 1 +
 1 file changed, 1 insertion(+)
```
<!-- /snippet -->

The driver is the command `true`: it changes nothing and exits with 0, so the version of the current branch stays in `%A`. The merge is clean. And the lock file is the version of `main`: the dependency that `feat/cache` added isn't in it. A lock file is generated, so the honest sequence is: keep one side, then regenerate from the merged manifest and commit.

Where silently keeping one side would be wrong, unset the attribute.

```bash
printf 'CHANGELOG.md      merge=union\nrequirements.lock -merge\n' > .gitattributes
git commit -q -am "Lock file: never merge by content"
git merge feat/cache
```

<!-- snippet: ch14c/attr-merge/04-unset -->
```text
$ printf 'CHANGELOG.md      merge=union\nrequirements.lock -merge\n' > .gitattributes
$ git commit -q -am "Lock file: never merge by content"
$ git merge feat/cache
Auto-merging CHANGELOG.md
warning: Cannot merge binary files: requirements.lock (HEAD vs. feat/cache)
Auto-merging requirements.lock
CONFLICT (content): Merge conflict in requirements.lock
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status -s
M  CHANGELOG.md
UU requirements.lock
$ cat requirements.lock
torch==2.4.0
limits==3.13.0
$ git ls-files -u
100644 59fbd9ace1e2d2383413a0183f124e7e501d03ec 1	requirements.lock
100644 09a1d7444516306c5387d7b61274d47d30e30803 2	requirements.lock
100644 b678f049b99091f662d137755b1bc3b3121cf6af 3	requirements.lock
```
<!-- /snippet -->

"Cannot merge binary files". The path conflicts, the working file is the version of the current branch without markers, and the three stages are in the index for you to choose from.

**[ON SCREEN]** Lower third: **GitHub**. Merges for a pull request run on GitHub's servers, where your driver configuration does not exist. The textbook adds: whether GitHub honors the built-in `union` driver is not stated in the pages read for this course, so treat merge attributes as a local aid.

**[TERMINAL]** Replay `labs/run ch14c/attr-filter`. The notebook was committed before the filter existed.

```bash
grep -c output_type eda.ipynb
git cat-file -p HEAD:eda.ipynb | grep -c output_type
```

<!-- snippet: ch14c/attr-filter/01-before -->
```text
# The notebook was committed with its outputs:
$ grep -c output_type eda.ipynb
1
$ git cat-file -p HEAD:eda.ipynb | grep -c output_type
1
```
<!-- /snippet -->

One output in the file, one in the committed blob.

<!-- snippet: ch14c/attr-filter/02-define -->
```text
$ cat tools/nbstrip.py
#!/usr/bin/env python3
"""clean filter for notebooks: drop outputs and execution counts (stdin to stdout)."""
import json
import sys

nb = json.load(sys.stdin)
for cell in nb["cells"]:
    if cell["cell_type"] == "code":
        cell["outputs"] = []
        cell["execution_count"] = None
json.dump(nb, sys.stdout, indent=1, sort_keys=True)
sys.stdout.write("\n")
$ printf '*.ipynb filter=nbstrip\n' > .gitattributes
$ git config set filter.nbstrip.clean 'python3 tools/nbstrip.py'
$ git config set filter.nbstrip.smudge cat
```
<!-- /snippet -->

The clean filter reads a notebook on standard input and writes it without outputs and execution counts. The smudge filter is `cat`: nothing is added on the way out. The attribute line names the filter, and the configuration defines it.

**[PAUSE]** The filter is defined. You have not touched the notebook. Predict `git status -s`.

```bash
git status -s
git add --renormalize .
git status -s
git add .gitattributes && git commit -q -m "Strip notebook outputs on the way into the repository"
git cat-file -p HEAD:eda.ipynb | grep -c output_type
grep -c output_type eda.ipynb
```

<!-- snippet: ch14c/attr-filter/03-renormalize -->
```text
$ git status -s
 M eda.ipynb
?? .gitattributes
$ git add --renormalize .
$ git status -s
M  eda.ipynb
?? .gitattributes
$ git add .gitattributes && git commit -q -m "Strip notebook outputs on the way into the repository"
$ git cat-file -p HEAD:eda.ipynb | grep -c output_type
0
$ grep -c output_type eda.ipynb
1
```
<!-- /snippet -->

Modified: its cleaned form differs from the stored blob. 🟡 CAUTION: `git add --renormalize .` stages the cleaned form. After the commit, the blob has no outputs and your file on disk still has them.

Now run the notebook again. The script simulates it by changing an execution count.

```bash
grep execution_count eda.ipynb
git status -s
git diff --stat
```

<!-- snippet: ch14c/attr-filter/04-rerun -->
```text
# Run the notebook again (simulated with sed): a new execution count, the same source.
$ sed 's/"execution_count": 7/"execution_count": 8/' eda.ipynb > eda.tmp && mv eda.tmp eda.ipynb
$ grep execution_count eda.ipynb
   "execution_count": 8,
$ git status -s
$ git diff --stat
```
<!-- /snippet -->

The file on disk differs from the blob, and `git status` and `git diff` are silent. That is the purpose. It is also a trap when you debug.

And now the hook. A teammate clones.

```bash
git clone -q server.git analysis-asha
cd analysis-asha
git check-attr filter -- eda.ipynb
git config get filter.nbstrip.clean
```

<!-- snippet: ch14c/attr-filter/05-clone -->
```text
$ cd ..
$ git clone -q server.git analysis-asha
$ cd analysis-asha
$ git check-attr filter -- eda.ipynb
eda.ipynb: filter: nbstrip
$ git config get filter.nbstrip.clean
[exit status: 1]
# Asha runs the notebook (simulated by copying an executed copy over it) and commits.
# Nothing strips her outputs, and nothing warns her:
$ cp ../executed.ipynb eda.ipynb
$ git commit -q -am "Rerun error analysis"
$ git cat-file -p HEAD:eda.ipynb | grep -c output_type
1
```
<!-- /snippet -->

Her clone knows that `eda.ipynb` has `filter=nbstrip`. `git config get` exits with status 1: there is no `filter.nbstrip.clean`. So the filter is a no-op. She runs the notebook and commits, and the rest of the snippet shows the outputs in history. Nothing stripped them, and nothing warned her. Row three of the table. Almost any of us would have made that commit.

## COMMON MISTAKES

Five mistakes to watch for.

1. **"The attribute is committed, so the filter runs for everyone."** Root cause: the attribute names a driver; the definition is configuration, which is not cloned, and a missing definition is a silent pass-through.
2. **Setting `required = true` to force teammates to have the filter.** Root cause: `required` is part of the definition that their clone lacks; it protects against a defined filter that fails.
3. **`merge=union` on a file where order or duplicates matter.** Root cause: union keeps the lines of both sides, in an order the manual calls random, and reports no conflict.
4. **A keep-ours driver for lock files with no check afterwards.** Root cause: the other side's dependency is silently dropped; the file must be regenerated and CI must verify it against the manifest.
5. **Trusting a textconv diff as the complete change.** Root cause: a rendering hides what it leaves out, and it never affects what is stored or what `format-patch` writes.

## PRODUCTION EXAMPLE

**[ANIMATION]** cards: id=arr question=Who_makes_sure_the_filter_is_defined? numbered=on cards=A_setup_step:every_clone_runs_it_once|A_tracked_configuration_file:each_engineer_includes_it_once|A_tool_installs_it:into_the_global_configuration,_as_git_lfs_install_does|A_CI_job:fails_when_the_stored_form_is_wrong marks=1:ring,4:lock title=Three_arrangements,_and_the_part_that_cannot_be_skipped at_2=75 at_4=30

**[ANIMATION]** step: 3

Now, out of the lab. After the 40-megabyte commit, the team reads the last paragraph of section 14C.8, which lists three arrangements that work. One: a setup step that every clone runs once executes the `git config set filter...` commands. Two: the definition lives in a tracked configuration file that each engineer includes once. Later changes to that file take effect on pull, which is code execution by pull request, so it is reviewed like CI configuration. Three: a tool installs its filter into the global configuration, as `git lfs install` does.

**[ANIMATION]** step: marks

They choose the first and add it to onboarding. Then they add the part that, in the textbook's words, can't be skipped in any of the three: a CI job, an automated check on the server, that fails when the stored form is wrong. The job checks every committed notebook for outputs. The filter is now a convenience on each laptop, and the guarantee is on the server.

## PRACTICE EXERCISE

Your turn. Do Lab 14.4, "A clean and smudge filter", in [`lab-manual/m14-hooks-rerere-attributes.md`](../../lab-manual/m14-hooks-rerere-attributes.md).

The lab builds a required pointer filter, a small model of a large-file extension. Before each `git cat-file -p` and each `cat` of the working file, predict which of the two forms you'll see. Before the failure scenario, in which a teammate without the definition commits, predict what ends up in the blob and whether Git prints anything.

The challenge is Exercise 14.5, Level 2, "A changelog that conflicts on every merge", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q59: "Explain "the attribute travels, the driver does not" for a diff driver, a merge driver and a required filter."

Answer out loud. I'll wait.

**[PAUSE]**

**[ANIMATION]** step: line.2

**[ANIMATION]** say: required_is_part_of_the_definition:_a_clone_without_it_has_neither

A strong answer first says where each half lives and which Git operations transfer it. It then goes through the three cases and states, for each, exactly what a clone without the definition does and whether it says anything. It treats the required filter separately and explains why the word "required" doesn't help in that clone. It gives the reason Git is designed this way, in terms of what a cloned repository must not be able to do to your machine. And it ends with what a team does about it, including the one control that doesn't depend on any laptop.

## RECAP

Let's land this. You should now be able to say:

- A `textconv` diff driver changes what I read in a diff, never what is stored or what a patch contains.
- `merge=union` keeps both sides' lines and can be wrong without a conflict; `-merge` always conflicts; a custom driver is a command that leaves its result in `%A`.
- A clean filter rewrites content on the way into the index and a smudge filter on the way out; the blob holds the cleaned form.
- A clone receives the attribute and not the definition, and a missing definition is silent, even for a required filter.
- Git LFS and notebook stripping are built on filters, and the guarantee for both has to come from CI.

## HOMEWORK

Read sections 14C.6 to 14C.8 of [Chapter 14C](../../textbook/ch14c-stash-rerere-attributes-hooks.md).

Today you let your own programs take part in diffs, merges and storage, and you know which half of each never leaves your machine. Before the next video, do the filter lab and predict each stored form. Next time: hooks, the programs that Git runs at fixed points. Until then, look at the state first and type second. See you in the next one.
