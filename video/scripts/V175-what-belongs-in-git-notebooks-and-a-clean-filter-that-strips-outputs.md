# V175: What belongs in Git, notebooks, and a clean filter that strips outputs

- **Part.** 8, Professional practice
- **Module.** 33
- **Planned minutes.** 26
- **Prerequisites.** V088, V174
- **Textbook sections.** [Chapter 28](../../textbook/ch28-ai-ml-workflows.md), sections 28.1 to 28.5
- **Demo scripts.** `labs/ch28/notebook-problem.sh` (snippets `01-anatomy` to `04-merge`), `labs/ch28/notebook-filter.sh` (snippets `01-the-filter` to `08-verify-in-ci`)

## HOOK

**[ON SCREEN]** "Security found an API key in a notebook. Nobody committed a key."

Both statements are true. The scanner's finding is real, and so is the engineer's protest. The source code of the notebook reads the key from an environment variable, which is the right way to handle a key. Nobody typed the key into any file.

**[ANIMATION]** cards: question=The_notebook_file_stores_what_cells_print cards=a_key_that_nobody_typed|a_notebook_nobody_edited_shows_as_modified|a_merge_conflict_leaves_a_file_Jupyter_cannot_open at_1=20 at_2=45 at_3=65

The key was printed by a cell, and the notebook file stores what cells print. That one fact also explains why a notebook that nobody edited shows as modified, and why two people who reran the same notebook get a merge conflict that leaves a file Jupyter can't open. Keep the notebook that nobody edited in mind. You'll count its changed lines yourself.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is the first of four videos on AI and ML repositories, Chapter 28. Three words first. A commit is one saved snapshot of the project, and history is the chain of all of them. A notebook is a document that mixes cells of code with the results of running them. And Jupyter is the program that runs it. The rule that organizes the chapter is one sentence: keep code and pointers in Git, and keep data, weights and outputs out of it. An ML project differs from a backend service in that most of its bytes aren't source code, and most of what determines a result isn't in a commit unless you put a reference to it there.

Two limits of the chapter, stated once, as the textbook states them. The tools of this field, nbstripout, nbdime, jupytext, DVC, pre-commit and others, aren't installed in the lab. Their commands are given from their documentation, in blocks without output, with the versions the course's research report recorded on the first of October 2026. What's run here is the mechanism under each tool, written with the Python standard library. The filter you'll see in the terminal is a small stand-in written for the lab. It isn't one of the named tools.

From video 88 you know what a clean filter is: a command that rewrites a file's content on its way into the repository. `.gitattributes` names a driver for a path pattern, and the Git configuration defines the command. Today's video takes that in the directions an ML team needs.

The demos use `docqa`, a small project that classifies support tickets and answers them from documentation.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Decide for a file in an ML project whether it belongs in Git, is referenced from Git, or is ignored.
2. Explain what a notebook file stores and why a rerun changes it without any edit.
3. Show how a notebook leaks a secret or data through its outputs.
4. Install a clean filter that strips outputs, mark it `required`, and verify it in CI.
5. Say what nbdime, jupytext and ReviewNB add to the filter, as the section describes them.

## CONCEPT

**What belongs in Git.** Git should hold what a human writes and reviews, plus small references to everything else. It shouldn't hold what a program produces or what is large.

**[ANIMATION]** cards: question=Three_properties_of_Git_decide_the_question numbered=on cards=Every_clone_carries_the_full_history:every_file,_in_every_version|Objects_cannot_be_recalled:removing_a_file_adds_a_commit|Diff,_merge_and_blame_work_on_lines_of_text

Three properties of Git decide the question. Every clone carries the full history, so a file committed once is downloaded by everyone, in every version, for as long as the history exists. Objects can't be recalled: removing a file adds a commit and removes nothing. And diff, merge and blame work on lines of text.

**[ANIMATION]** walk: columns=on_GitHub,what_happens rows=a_file_larger_than_50_MiB:a_warning|a_file_larger_than_100_MiB:blocked|a_repository:ideally_under_1_GB,_strongly_under_5_GB|Git:not_designed_to_serve_as_a_backup_tool marks=1.2:wait,2.2:bad mono=off title=The_platform's_limits

On top of that the platform sets limits: GitHub warns about files larger than 50 mebibytes, blocks files larger than 100 mebibytes, recommends that repositories stay ideally under 1 gigabyte and strongly under 5 gigabytes, and states that Git isn't designed to serve as a backup tool.

**[ON SCREEN]** The split of section 28.2.

| In Git | Not in Git; referenced from Git |
|---|---|
| source code and tests | raw and processed data sets |
| configuration, including evaluation settings | checkpoints and exported weights |
| prompts and evaluation specifications | experiment-tracker stores (`mlruns/`, `mlflow.db`, `wandb/`) |
| lock files | virtual environments and caches |
| Dockerfiles and CI workflows | build outputs, logs, run directories |
| notebooks **without outputs** | notebook outputs |
| pointer and metadata files (a checksum, a model ID with a pinned revision) | secrets, in any form |

Read it as two columns: what Git holds, and what Git only references.

**[ANIMATION]** end

Quick quiz. Three files: a prompt for the model, a checkpoint of trained weights, and a lock file. Which one stays out of Git? A, the prompt. B, the checkpoint. C, the lock file. Your answer?

**[PAUSE]**

B, the checkpoint. It's large, a program produced it, and Git holds a pointer to it instead. The prompt and the lock file were on the left of the table.

The textbook is careful about the status of this table: the split is the research report's inference from the limits, not a published standard. The less obvious rows are prompts and pointers. A prompt is source code for an LLM application: a one-word change alters behavior, so it deserves a diff, a review and a commit. A pointer is what makes the right-hand column reproducible: Git can't hold the data, but it can hold forty or sixty-four hexadecimal characters that identify exactly one version of it.

The same split is a security boundary. The left column is what you're prepared to show every engineer, contractor and CI job with read access.

**[ANIMATION]** stores: boxes=an_.ipynb_file:one_JSON_document|a_code_cell|an_output rows=1:A:metadata|1:A:nbformat,_nbformat__minor|1:A:cells@hl|2:B:source|2:B:outputs@hl|2:B:execution__count|3:C:a_stream:_what_was_printed|3:C:a_result|3:C:an_error_with_its_traceback|3:C:display_data:_a_base64_image arrows=2:A3>B:each_cell|3:B2>C:each_output mono=on id=ipynb

**[ANIMATION]** step: ipynb.1

**Notebooks.** An `.ipynb` file is one JSON document in which each code cell carries its source, the outputs of its last run and a counter, so running a notebook changes the file even when no code changed.

**[ANIMATION]** step: ipynb.3

JSON is a plain-text format of names and values. Precisely: the notebook format defines a top-level object with `metadata`, `nbformat`, `nbformat_minor` and `cells`. A code cell stores `source`, a list of `outputs` and an `execution_count`. An output can be a stream, which is what was printed, a result, an error with its traceback, or display data such as a base64-encoded image.

**[ANIMATION]** cards: question=One_design_decision,_three_problems numbered=on cards=A_rerun_is_a_change|Outputs_carry_data_and_credentials_into_history|A_line-based_merge_can_produce_a_file_that_is_not_a_notebook

That one design decision causes three separate problems, and the demo shows each: a rerun is a change. Outputs carry data and credentials into history. And a line-based merge can produce a file that isn't a notebook.

**[ANIMATION]** trees: file=notebook.ipynb in=wt commits=none forms=with_outputs,-,- forms_add=with_outputs,no_outputs,- forms_commit=with_outputs,no_outputs,no_outputs steps=setup,add,commit versions=the_notebook,the_notebook,the_notebook title=A_clean_filter_on_the_way_in id=clean

**A clean filter that strips outputs.** A clean filter rewrites a notebook on its way into the repository so that the blob has no outputs, while the file in your working tree keeps them. The blob is Git's stored copy of the file's content, and the working tree is the folder of ordinary files you edit.

**[ANIMATION]** end

The maintained implementation is nbstripout, version 0.9.1 of February 2026. From its documentation, not run here:

```bash
nbstripout --install                              # filter into this clone's .git/config, attributes into .git/info/attributes
nbstripout --install --attributes .gitattributes  # attributes into a committed file instead
nbstripout --status                               # is the filter installed in this clone?
nbstripout --verify notebooks/*.ipynb             # exit non-zero if anything would be stripped: the CI form
```

Its README states the limitation that shapes everything else: there's no way to have Git set up the filter automatically when someone clones a repository, by design, so that a clone never executes arbitrary code.

**[ANIMATION]** cards: question=A_filter_that_cannot_run cards=optional,_the_default:not_an_error:_a_no-op_passthru|required_=_true ask=2 marks=1:bad,2:lock id=req

**[ANIMATION]** step: req.2

**What `required` changes.** A filter is optional by default. The manual says a missing driver definition, or a driver that exits with an error, "is not an error but makes the filter a no-op passthru". For a filter whose purpose is to keep outputs out of history, a silent pass-through is the worst possible failure.

**[ANIMATION]** end

**The complementary tools.** They're complementary, not alternatives.

**[ON SCREEN]** The table of section 28.5. Commands of these tools come from their documentation and are not run here.

| Tool (version on 1 October 2026) | What it controls | Mechanism in Git terms |
|---|---|---|
| nbstripout (0.9.1) | what enters history | a clean filter |
| nbdime (4.0.4) | how notebooks are diffed and merged locally | a diff driver, a merge driver and a merge tool |
| jupytext (1.19.5) | what gets reviewed | pairs the notebook with a plain-text file |
| ReviewNB (commercial GitHub app) | review of notebooks **with** outputs | comments on rendered notebook diffs in pull requests |

nbdime understands the notebook structure, so it can show a cell-level diff and can merge two reruns by resolving generated values such as execution counters, instead of writing conflict markers into JSON. Like every driver, its definitions live in each clone's configuration: a colleague who hasn't run its setup command gets Git's line-based behavior, with no warning.

jupytext takes the other road: don't review the `.ipynb` at all. It pairs the notebook with a text file that contains only the cell inputs, so a pull request shows an ordinary Python diff. The README's own recipe is to commit the text file and, unless you want outputs versioned, to keep the `.ipynb` out of version control.

| Situation | Reasonable choice |
|---|---|
| Notebooks are exploration; nobody reviews outputs | strip outputs (nbstripout), verify in CI |
| Notebooks contain logic that is reviewed like code | pair with jupytext and review the `.py`; ignore or strip the `.ipynb` |
| Outputs are the deliverable and must be discussed | commit them on purpose, and use a tool built to review them (ReviewNB, or nbdime's web viewers locally) |
| Notebook logic keeps growing | move it into the package under `src/` and import it; the notebook becomes a thin caller |

The last row is the durable fix. A function in `src/docqa/` has tests, a diff and a blame history. A cell has none of them.

**GitHub, not Git.** GitHub renders `.ipynb` files as static HTML. Its rich notebook diff is still the feature preview announced on the first of March 2023, in which you can't comment on lines. No general-availability announcement was found. Unverified: whether the redesigned "Files changed" page renders notebook rich diffs. The report didn't check a signed-in interface. Treat it as a viewer, not as the basis of a review process.

## MENTAL MODEL

Two analogies from the textbook, one per half of the video.

**[ANIMATION]** stores: boxes=the_lab_notebook:Git|the_freezer:storage_outside_Git rows=1:A:the_protocol_and_the_settings|1:A:the_label_of_every_sample|2:B:the_samples|3:A:a_checksum_of_the_contents@hl arrows=3:A3>B1:verifies title=A_lab_notebook_and_a_freezer

For what belongs in Git: a lab notebook and a freezer. The notebook records the protocol, the settings and the label of every sample. The samples live in the freezer. Nobody tapes a sample into the notebook, and nobody runs a lab from the freezer alone. The analogy breaks in one useful way: a Git "notebook" can verify the freezer, because the label it records can be a checksum of the contents.

**[ANIMATION]** replay: clean

For the filter: a mail room that removes attachments from outgoing letters and files the plain letter. Your desk copy still has the attachments. Where it breaks: every desk has its own mail room, and a new employee's desk has none until somebody sets it up.

**[ANIMATION]** stores: boxes=your_clone|the_repository|a_new_clone rows=1:A:.gitattributes:_the_attribute|1:A:.git/config:_the_driver|2:B:.gitattributes@ok|3:C:.gitattributes@ok|3:C:no_driver_in_.git/config@bad arrows=2:A1>B1:push|3:B1>C1:clone title=The_attribute_travels._The_driver_does_not id=travel

That last sentence is the whole second half of the video. The attribute travels with the repository. The mail room does not. So the filter is a convenience, and the control is something else.

**[ANIMATION]** end

Try it now, on paper, for thirty seconds. Write down the three things a code cell stores, and put a tick beside the one a human writes. I'll wait.

**[PAUSE]**

## DIAGRAM

**[DIAGRAM]** A new drawing: one notebook cell as JSON, with its three parts marked. Draw the braces first, then mark each field.

```text
  {
   "cell_type": "code",
   "execution_count": 4,          <-- counter           strip (changes on every run)
   "outputs": [ ... ],            <-- what a program    strip (printed text, tables,
                                      produced                 images, tracebacks)
   "source": [ ... ]              <-- what a human      keep  (the only reviewed part)
                                      wrote
  }
```

One object, three kinds of content: a counter, the outputs and the source. A human wrote one of them, the source. That's your tick.

**[ON SCREEN]** The root-cause box of section 28.3, one line at a time.

```text
Observed behavior : a notebook nobody edited shows as modified, conflicts on merge, and
                    contains a credential nobody typed.
Git state         : the blob for the .ipynb holds source, outputs and execution counts.
Mechanism         : Jupyter saves the result of the last run into the same file as the code.
                    Git stores and compares the file as lines of text.
Root cause        : one file mixes what a human wrote with what a program produced.
Why Git does this : Git has no knowledge of file formats. Content awareness is added through
                    filter, diff and merge drivers, and those must be configured.
Correct fix       : keep outputs out of the blob (a clean filter, section 28.4), or review a
                    paired text file instead (jupytext, section 28.5).
Prevention        : enforce the choice in CI, because the filter lives in each clone's
                    configuration and a clone does not have it.
```

And the root-cause box of section 28.3. Read the root cause line: one file mixes what a human wrote with what a program produced.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch28/notebook-problem`. The lab cannot run Jupyter, so a script writes the file Jupyter would save after run number N: the same sources every time, and different counters, printed text and chart bytes. The key in it is a fake one that says so.

Into the lab. It can't run Jupyter, so a script writes the file Jupyter would save after each run. The key in it is a fake one, and it says so.

**Step 1: the anatomy of one cell.**

```bash
sed -n '10,29p' notebooks/01-error-analysis.ipynb
```

<!-- snippet: ch28/notebook-problem/01-anatomy -->
```text
# One code cell of the committed notebook: source, outputs and a counter in one object.
$ sed -n '10,29p' notebooks/01-error-analysis.ipynb
  },
  {
   "cell_type": "code",
   "execution_count": 4,
   "id": "load",
   "metadata": {},
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "using key sk-demo-not-a-real-key-0001\n"
     ]
    }
   ],
   "source": [
    "import os\n",
    "key = os.environ[\"LLM_API_KEY\"]\n",
    "print(\"using key\", key)"
   ]
```
<!-- /snippet -->

Source, output and counter sit in one object. Read the source: it takes the key from the environment and prints it. Read the output: the printed line is stored.

**Step 2: a rerun is a change.** Run all cells again without editing anything. Predict: how many lines will `git diff` report, and how many of them are code? Say it out loud.

**[PAUSE]**

```bash
git diff --stat
git diff | grep '^[-+] ' | cut -c1-76
```

<!-- snippet: ch28/notebook-problem/02-rerun -->
```text
# Run all cells again without editing any code (simulated: the file Jupyter would save):
$ git diff --stat
 notebooks/01-error-analysis.ipynb | 12 ++++++------
 1 file changed, 6 insertions(+), 6 deletions(-)
$ git diff | grep '^[-+] ' | cut -c1-76
-   "execution_count": 4,
+   "execution_count": 7,
-      "using key sk-demo-not-a-real-key-0001\n"
+      "using key sk-demo-not-a-real-key-0002\n"
-   "execution_count": 5,
+   "execution_count": 8,
-     "execution_count": 5,
+     "execution_count": 8,
-   "execution_count": 6,
+   "execution_count": 9,
-      "image/png": "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJyg
+      "image/png": "AAIEBggKDA4QEhQWGBocHiAiJCYoKiwuMDI0Njg6PD5AQkRGSEpMTlB
```
<!-- /snippet -->

Six lines changed and none of them is code: three counters, one of them stored twice, one printed line, one image. There's the notebook that nobody edited, from the opening. A reviewer who opens this diff learns nothing, and after a few such commits nobody opens notebook diffs at all.

**Step 3: outputs carry credentials into history.**

```bash
git grep -n "sk-demo" $(git rev-list HEAD) -- notebooks | cut -c1-110
wc -c < notebooks/01-error-analysis.ipynb
```

<!-- snippet: ch28/notebook-problem/03-secret -->
```text
# The first cell printed a credential. It is now in two commits:
$ git grep -n "sk-demo" $(git rev-list HEAD) -- notebooks | cut -c1-110
5e95f6c14957c3a89416fb5587e9913a0c04dcde:notebooks/01-error-analysis.ipynb:21:      "using key sk-demo-not-a-r
ac8532561836542f31df0ed0c49a3213816c29ea:notebooks/01-error-analysis.ipynb:21:      "using key sk-demo-not-a-r
$ wc -c < notebooks/01-error-analysis.ipynb
    3558
$ python3 -c "import json,sys; nb=json.load(open(sys.argv[1])); print(sum(len(json.dumps(c['outputs'])) for c in nb['cells'] if c['cell_type']=='code'), 'bytes of outputs')" notebooks/01-error-analysis.ipynb
2429 bytes of outputs
```
<!-- /snippet -->

The value is in two commits. And 2,429 of 3,558 bytes of this small notebook are outputs. With real charts the proportion is far higher. The same holds for a data frame preview that shows customer rows: no secret scanner has a pattern for "a table that should not be here". One caveat the textbook marks as unverified: how often secrets leak through notebook outputs specifically. The research found mechanisms, not numbers.

**Step 4: the merge.** Two people rerun the same notebook on two branches. 🟡 CAUTION: `git merge` moves the current branch when it succeeds. Predict: will the file be a valid notebook afterwards? Yes or no?

**[PAUSE]**

```bash
git merge asha/rerun
grep -c '^<<<<<<<' notebooks/01-error-analysis.ipynb
python3 -m json.tool notebooks/01-error-analysis.ipynb > /dev/null
```

<!-- snippet: ch28/notebook-problem/04-merge -->
```text
# Two people rerun the same notebook on two branches:
$ git merge asha/rerun
Auto-merging notebooks/01-error-analysis.ipynb
CONFLICT (content): Merge conflict in notebooks/01-error-analysis.ipynb
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ grep -c '^<<<<<<<' notebooks/01-error-analysis.ipynb
6
$ python3 -m json.tool notebooks/01-error-analysis.ipynb > /dev/null
Expecting property name enclosed in double quotes: line 13 column 1 (char 185)
[exit status: 1]
```
<!-- /snippet -->

Six conflict regions, written into the middle of a JSON document. The file no longer parses. Jupyter can't open it to let you resolve the conflict. The root-cause box from the diagram says why.

**[TERMINAL]** Now the fix. Replay `labs/run ch28/notebook-filter`.

**Step 5: how such a tool works.**

```bash
sed -n '10,31p' tools/nbstrip.py
```

<!-- snippet: ch28/notebook-filter/01-the-filter -->
```text
$ sed -n '10,31p' tools/nbstrip.py
DROP_CELL_METADATA = ("collapsed", "scrolled", "execution")


def strip(nb):
    """Remove everything that running the notebook adds. Returns the same object."""
    for cell in nb.get("cells", []):
        if cell.get("cell_type") == "code":
            cell["outputs"] = []
            cell["execution_count"] = None
        for key in DROP_CELL_METADATA:
            cell.get("metadata", {}).pop(key, None)
    nb.get("metadata", {}).pop("widgets", None)
    return nb


def dump(nb):
    # The layout Jupyter itself writes: one-space indent, keys in file order, final newline.
    return json.dumps(nb, indent=1, ensure_ascii=False) + "\n"


def main(argv):
    if argv[:1] == ["--verify"]:
```
<!-- /snippet -->

Parse the JSON, empty `outputs`, set `execution_count` to null, drop the metadata that execution adds, and write the document back in the layout Jupyter itself uses. The last part matters: if the filter reformatted the file, every notebook would show as changed the first time it passed through. Cleaning cleaned content must change nothing.

**Step 6: configure.** 🟡 CAUTION: `git config set` changes `.git/config`, a file that keeps no history. The subcommand form needs Git 2.46 or later.

```bash
git check-attr filter -- notebooks/01-error-analysis.ipynb
git config set filter.nbstrip.clean "python3 tools/nbstrip.py"
git config set filter.nbstrip.smudge cat
git config set filter.nbstrip.required true
```

<!-- snippet: ch28/notebook-filter/02-configure -->
```text
$ git check-attr filter -- notebooks/01-error-analysis.ipynb
notebooks/01-error-analysis.ipynb: filter: nbstrip
$ git config set filter.nbstrip.clean "python3 tools/nbstrip.py"
$ git config set filter.nbstrip.smudge cat
$ git config set filter.nbstrip.required true
```
<!-- /snippet -->

The attribute is already committed in `.gitattributes`. `git check-attr` confirms which driver applies to the path. The driver itself is defined in this clone's configuration.

**Step 7: add and commit.** Predict: after the commit, how many outputs does the file on disk have, and how many does the blob have? Say both numbers.

**[PAUSE]**

```bash
git add tools/nbstrip.py notebooks
git commit -q -m "Add notebook filter and the error-analysis notebook"
grep -c output_type notebooks/01-error-analysis.ipynb
git cat-file -p HEAD:notebooks/01-error-analysis.ipynb | grep -c output_type
git cat-file -s HEAD:notebooks/01-error-analysis.ipynb
```

<!-- snippet: ch28/notebook-filter/03-add -->
```text
$ git add tools/nbstrip.py notebooks
$ git commit -q -m "Add notebook filter and the error-analysis notebook"
checks: 2 file version(s) examined, 0 problem(s)
# The file on disk still has its outputs. The blob in the repository does not:
$ grep -c output_type notebooks/01-error-analysis.ipynb
3
$ git cat-file -p HEAD:notebooks/01-error-analysis.ipynb | grep -c output_type
0
$ git cat-file -p HEAD:notebooks/01-error-analysis.ipynb | sed -n '10,20p'
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "load",
   "metadata": {},
   "outputs": [],
   "source": [
    "import os\n",
    "key = os.environ[\"LLM_API_KEY\"]\n",
    "print(\"using key\", key)"
$ wc -c < notebooks/01-error-analysis.ipynb
    3558
$ git cat-file -s HEAD:notebooks/01-error-analysis.ipynb
967
```
<!-- /snippet -->

The file on disk has three outputs and 3,558 bytes. The blob has none and 967 bytes. The `checks:` line is the project's pre-commit hook reporting. That is video 177.

**[ON SCREEN]** The state table of section 28.4.

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git config set filter.nbstrip.clean ...` | unchanged | unchanged | unchanged | unchanged | `.git/config` gains the driver | unchanged | unchanged |
| `git add notebook.ipynb` with the filter | unchanged: outputs stay | entry points at a blob of the **cleaned** content | unchanged | unchanged | one new blob | unchanged | unchanged |
| `git add --renormalize .` | unchanged | every tracked file re-cleaned; entries change where the cleaned form differs | unchanged | unchanged | new blobs | unchanged | unchanged |
| `git restore <notebook>`, or `git switch` to a commit where the notebook differs | file rewritten from the **cleaned** blob (smudge is `cat`): local outputs are gone | updated | as usual | as usual | as usual | unchanged | unchanged |

The first row: configuring the filter only adds the driver to .git/config.

The second row: git add leaves the outputs in the working tree, and the index entry points at a blob of the cleaned content.

The third row is how you apply a new filter to notebooks that are already tracked.

The last row is the price: the outputs exist only in your working tree, and any command that rewrites the file from the repository discards them.

**Step 8: rerunning is no longer a change.**

```bash
grep -c 'not-a-real-key-0002' notebooks/01-error-analysis.ipynb
git status --short
git diff --stat
```

<!-- snippet: ch28/notebook-filter/04-rerun -->
```text
# Rerun the notebook (simulated). The file changes; what Git would store does not:
$ grep -c 'not-a-real-key-0002' notebooks/01-error-analysis.ipynb
1
$ git status --short
$ git diff --stat
```
<!-- /snippet -->

The file contains the second run's printed key, and `git status` is silent.

**[ANIMATION]** hash: differs=byte steps=one,same left=the_first_run,_cleaned right=the_rerun,_cleaned lines=source:_kept,outputs:_empty,execution__count:_null ids=ed9abfc,ed9abfc fn=hash title=Rerun,_clean,_compare same=Cleaned,_both_runs_are_the_same_bytes:_the_same_blob_ID

Why silent? Git compares the cleaned form of the file with the index, its list of what the next commit will hold. Cleaned, the first run and the rerun are the same bytes, and the same bytes always get the same blob ID.

**[ANIMATION]** end

A change to the code of a cell still shows, as a one-line diff a reviewer can read:

<!-- snippet: ch28/notebook-filter/05-real-change -->
```text
# A change to the code of a cell is still a change:
$ sed -i.bak 's/plot_confusion(errors)/plot_confusion(errors, normalize=True)/' notebooks/01-error-analysis.ipynb && rm notebooks/01-error-analysis.ipynb.bak
$ git status --short
 M notebooks/01-error-analysis.ipynb
$ git diff
diff --git a/notebooks/01-error-analysis.ipynb b/notebooks/01-error-analysis.ipynb
index ed9abfc..42ce0ef 100644
--- a/notebooks/01-error-analysis.ipynb
+++ b/notebooks/01-error-analysis.ipynb
@@ -38,7 +38,7 @@
    "metadata": {},
    "outputs": [],
    "source": [
-    "plot_confusion(errors)"
+    "plot_confusion(errors, normalize=True)"
    ]
   }
  ],
```
<!-- /snippet -->

**Step 9: what `required` changes.** The driver is pointed at a program that doesn't exist. Predict the exit status of `git add` with `required` set, and with it unset.

**[PAUSE]**

```bash
git config set filter.nbstrip.clean nbstrip-not-installed
git add notebooks/01-error-analysis.ipynb
git status --short
git config unset filter.nbstrip.required
git add notebooks/01-error-analysis.ipynb
git cat-file -p :notebooks/01-error-analysis.ipynb | grep -c output_type
```

<!-- snippet: ch28/notebook-filter/06-required -->
```text
# required = true: a filter that cannot run stops the operation instead of passing content through.
$ git config set filter.nbstrip.clean nbstrip-not-installed
$ git add notebooks/01-error-analysis.ipynb
error: cannot run nbstrip-not-installed: No such file or directory
error: cannot fork to run external filter 'nbstrip-not-installed'
error: external filter 'nbstrip-not-installed' failed
fatal: notebooks/01-error-analysis.ipynb: clean filter 'nbstrip' failed
[exit status: 128]
$ git status --short
 M notebooks/01-error-analysis.ipynb
# The same with required unset: the outputs go in, with only a warning.
$ git config unset filter.nbstrip.required
$ git add notebooks/01-error-analysis.ipynb
error: cannot run nbstrip-not-installed: No such file or directory
error: cannot fork to run external filter 'nbstrip-not-installed'
error: external filter 'nbstrip-not-installed' failed
[exit status: 0]
$ git cat-file -p :notebooks/01-error-analysis.ipynb | grep -c output_type
3
```
<!-- /snippet -->

With `required = true`, `git add` fails with status 128 and nothing is staged. With it unset, the same three error lines appear, the exit status is 0, and the notebook is staged with its three outputs.

**[ANIMATION]** step: req.marks

nbstripout declares its filter required for this reason.

**[ANIMATION]** end

**Step 10: what a clone has.** Predict: Asha clones. Which of the two halves does she get, the attribute or the driver?

**[PAUSE]**

```bash
git clone -q ../server.git ../docqa-asha && cd ../docqa-asha
git check-attr filter -- notebooks/01-error-analysis.ipynb
git config get filter.nbstrip.clean
git commit -q -am "Rerun error analysis" && git push -q
git cat-file -p HEAD:notebooks/01-error-analysis.ipynb | grep -c output_type
```

<!-- snippet: ch28/notebook-filter/07-clone -->
```text
# A clone gets the attribute and the script, not the configuration:
$ git clone -q ../server.git ../docqa-asha && cd ../docqa-asha
$ git check-attr filter -- notebooks/01-error-analysis.ipynb
notebooks/01-error-analysis.ipynb: filter: nbstrip
$ git config get filter.nbstrip.clean
[exit status: 1]
# Asha reruns the notebook and commits. Nothing strips it and nothing warns her:
$ git commit -q -am "Rerun error analysis" && git push -q
$ git cat-file -p HEAD:notebooks/01-error-analysis.ipynb | grep -c output_type
3
```
<!-- /snippet -->

The attribute travelled, because `.gitattributes` is a tracked file.

**[ANIMATION]** step: travel.3

The driver did not, because it lives in `.git/config`, and Git never copies configuration from a clone source: if it did, cloning a repository would let its author run commands on your machine. `required = true` didn't help either, since that setting is part of the same missing configuration. Asha's notebook went in with outputs and nothing warned her. She did nothing wrong. Her clone was never told.

**[ANIMATION]** end

**Step 11: the check that does travel.**

```bash
python3 tools/nbstrip.py --verify $(git ls-files "*.ipynb")
git switch -q --detach HEAD~1
python3 tools/nbstrip.py --verify $(git ls-files "*.ipynb")
```

<!-- snippet: ch28/notebook-filter/08-verify-in-ci -->
```text
# What CI runs on a fresh checkout of each commit:
$ python3 tools/nbstrip.py --verify $(git ls-files "*.ipynb")
not stripped: notebooks/01-error-analysis.ipynb
[exit status: 1]
$ git switch -q --detach HEAD~1
$ python3 tools/nbstrip.py --verify $(git ls-files "*.ipynb")
[exit status: 0]
```
<!-- /snippet -->

`--verify` strips each committed notebook in memory and fails if the result differs from the file. On a fresh checkout the files are the blobs, so this is a check of what is in history. It fails on Asha's commit and passes on the one before.

**[ANIMATION]** gates: packet=a_notebook_with_outputs gates=the_clean_filter:skip:each_laptop:a_convenience,_missing_in_a_new_clone|--verify_in_CI:stop:a_required_check:on_a_fresh_checkout zones=your_machine,the_server split=1 result=not_stripped:_exit_status_1 title=The_check_that_does_travel

Run as a required check in CI, the automation that tests every change on a server, it's the control. The filter on each laptop is a convenience that keeps people from tripping it.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Believing "we use nbstripout" describes the repository.** Root cause: the filter is configuration in each clone, and a clone that never ran the install has no filter.
2. **Leaving the filter optional.** Root cause: by default a filter that cannot run is a silent pass-through, so the unstripped content is staged with exit status 0.
3. **Printing a secret "only to check it".** Root cause: what a cell prints is stored in the notebook file and enters history with the next commit.
4. **A filter that reformats.** Root cause: if cleaning already-clean content changes it, every notebook shows as modified the first time it passes through.
5. **Expecting local outputs to survive a restore or a switch.** Root cause: the blob holds the cleaned form, and the smudge side does not put outputs back.

## PRODUCTION EXAMPLE

Now, out of the lab. A team that builds a retrieval pipeline keeps its error-analysis notebooks in the repository. A scanner reports a provider key on `main`. The response follows video 166: the key is revoked first. Then the lead asks the assessment question, how did it get there, and the answer is not "somebody committed a key". A debugging cell printed the client configuration.

**[ANIMATION]** cards: question=The_team_already_"used_nbstripout" cards=three_of_seven_clones:had_the_filter_installed|two_contractors:cloned_later_and_never_ran_the_install|the_verify_form:a_required_check,_on_a_fresh_checkout|the_filter_on_laptops:stays,_as_a_convenience marks=1:ring,2:bad,3:ok at_2=30 at_3=50 at_4=62

The team already "used nbstripout". The lead checks what that means: three of seven clones had the filter installed. Two contractors had cloned later and never ran the install. So the change isn't a reminder to install it. The verify form of the tool becomes a required check on pull requests, on a fresh checkout. The filter stays on laptops as a convenience. And because stripping outputs is also a data-protection control, the team decides what to do with the two notebooks whose charts are the deliverable: the figures are exported to a tracked report file, and the notebooks are stripped like the rest.

## PRACTICE EXERCISE

Your turn. Do Exercise 33.3, Level 2, "The notebook that nobody edited", in [`exercises/m32-m34-practice.md`](../../exercises/m32-m34-practice.md).

Before you look at any diff in the exercise, predict which three kinds of line can change in a notebook when no code changed. Before you check the clone, predict which of `git check-attr filter` and `git config get filter.<name>.clean` will give an answer there. Then do the exercise and compare.

The challenge is Exercise 33.1, Level 1, "In Git, or referenced from Git?", in the same file. It is Level 1, and worth doing carefully: write the reason for each path, not only the column.

## INTERVIEW QUESTION

**[ON SCREEN]** Q362: "Your team "uses nbstripout", and a notebook with outputs is on `main`. How did it get there, and what do you change?"

**[PAUSE]**

Answer out loud. A strong answer separates the two halves of a filter, the part that is a tracked file and the part that is configuration, and says which one a clone receives and why Git is designed that way. It lists more than one path by which an unstripped notebook reaches the server. It explains what the `required` setting protects against and what it cannot. And it names the control that doesn't depend on any laptop, and where that control runs. If you add what you would do about the notebook that is already in history, and in which order, you have connected this video to video 166.

## RECAP

Let's land this, in your own words.

- Git holds what a human writes and reviews, plus pointers; data, weights, outputs and secrets stay out.
- A notebook file stores source, outputs and counters in one object, so a rerun is a change, outputs enter history, and a line-based merge can break the JSON.
- A clean filter stores the stripped form in the blob while the working tree keeps the outputs.
- `required = true` turns a filter that cannot run from a silent pass-through into an error.
- The attribute travels with the repository and the driver does not, so the control is a required CI check on a fresh checkout.

## HOMEWORK

Read sections 28.1 to 28.5. If your own team keeps notebooks in a repository, check one clone with the two commands of step 10 and write down what you find.

Today you opened a notebook file, saw what it really stores, and built the control that keeps outputs out of history. That's a real protection for your team's keys and data. The next video is about the right-hand column of today's table: data and models, versioned by reference, and what a commit ID doesn't tell you about a run. Until then, look at the state first and type second. See you in the next one.
