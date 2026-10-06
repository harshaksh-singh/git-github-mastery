# Chapter 28: AI/ML workflows

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/ch28/`.

## 28.1 Why this matters

Four questions from a CTO to the engineer who owns the model repository:

1. "The evaluation dashboard says accuracy 0.90 for the run we showed the board. Check out the commit it names and show me 0.90." You check it out and get 0.80.
2. "The clone takes eleven minutes. Why?"
3. "Security found an API key in a notebook. Nobody committed a key."
4. "The pre-commit hooks block large files. How did a 900 kB dump reach `main`?"

Each has a cause you can name by the end of this chapter. The run was made from a working tree with an uncommitted change, and the tracker recorded only the commit (section 28.7). A checkpoint was committed two years ago and "deleted", and every clone still carries it (section 28.9). The key was printed by a cell, and the notebook file stores what cells print (section 28.3). And a hook that is not installed does not run (section 28.10).

The rule that organizes the chapter: **keep code and pointers in Git, and keep data, weights and outputs out of it.** An ML project differs from a backend service in that most of its bytes are not source code, and most of what determines a result (the data, the weights, the resolved configuration, the environment) is not in a commit unless you put a reference to it there.

Two limits of this chapter, stated once. The tools of this field (DVC, nbstripout, nbdime, jupytext, pre-commit, promptfoo, MLflow and others) are not installed in the lab, so their commands are given from their documentation, in blocks without output, with the versions and dates the Phase 0 report recorded on 1 October 2026. What is run here is the mechanism under each tool, written with the Python standard library: a clean filter, a pointer file with a checksum, a function that records the commit and the dirty state. The scripts are in `labs/ch28/files/`; each is short enough to read in full, and reading them is the point.

The demos use `docqa`, a small project that classifies support tickets and answers them from documentation.

## 28.2 What belongs in Git, and what does not

**In one sentence.** Git should hold what a human writes and reviews, plus small references to everything else; it should not hold what a program produces or what is large.

**Analogy.** A lab notebook and a freezer. The notebook records the protocol, the settings and the label of every sample; the samples live in the freezer. Nobody tapes a sample into the notebook, and nobody runs a lab from the freezer alone. The analogy breaks in one useful way: a Git "notebook" can verify the freezer, because the label it records can be a checksum of the contents.

**Precisely.** Three properties of Git decide the question. Every clone carries the full history, so a file committed once is downloaded by everyone, in every version, for as long as the history exists ([Chapter 3: Git internals](ch03-git-internals.md)). Objects cannot be recalled: removing a file adds a commit and removes nothing. And diff, merge and blame work on lines of text. On top of that the platform sets limits: GitHub warns about files larger than 50 MiB, blocks files larger than 100 MiB, recommends that repositories stay ideally under 1 GB and strongly under 5 GB, and states that Git is not designed to serve as a backup tool ([about large files on GitHub](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github)).

| In Git | Not in Git; referenced from Git |
|---|---|
| source code and tests | raw and processed data sets |
| configuration, including evaluation settings | checkpoints and exported weights |
| prompts and evaluation specifications | experiment-tracker stores (`mlruns/`, `mlflow.db`, `wandb/`) |
| lock files | virtual environments and caches |
| Dockerfiles and CI workflows | build outputs, logs, run directories |
| notebooks **without outputs** | notebook outputs |
| pointer and metadata files (a checksum, a model ID with a pinned revision) | secrets, in any form |

This split is the report's inference from the limits above, not a published standard. The less obvious rows are prompts and pointers. A prompt is source code for an LLM application: a one-word change alters behavior, so it deserves a diff, a review and a commit. A pointer is what makes the right-hand column reproducible: Git cannot hold the data, but it can hold forty or sixty-four hexadecimal characters that identify exactly one version of it.

**In production.** The same split is a security boundary. The left column is what you are prepared to show every engineer, contractor and CI job with read access. Customer data, weights you licensed and credentials need access control that a Git repository does not give you per file.

## 28.3 Notebooks: a JSON file that stores code, outputs and counters together

**In one sentence.** An `.ipynb` file is one JSON document in which each code cell carries its source, the outputs of its last run and a counter, so running a notebook changes the file even when no code changed.

**Precisely.** The notebook format defines a top-level object with `metadata`, `nbformat`, `nbformat_minor` and `cells`. A code cell stores `source`, a list of `outputs` and an `execution_count`; an output can be a stream (what was printed), a result, an error with its traceback, or display data such as a base64-encoded `image/png` ([nbformat](https://nbformat.readthedocs.io/en/latest/format_description.html)).

**See it.** One code cell of a committed notebook. The lab cannot run Jupyter, so `labs/ch28/files/make_notebook.py` writes the file Jupyter would save after run number N: the same sources every time, and different counters, printed text and chart bytes.

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

Source, output and counter sit in one object. That one design decision causes three separate problems.

**Problem 1: a rerun is a change.** Run all cells again without editing anything:

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

Six lines changed and none of them is code: three counters (one of them stored twice), one printed line, one image. A reviewer who opens this diff learns nothing, and after a few such commits nobody opens notebook diffs at all.

**Problem 2: outputs carry data and credentials into history.**

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

The source of the cell reads a key from the environment, which is the right way to handle a key. The cell also printed it, and what a cell prints is part of the file. The value (a fake one here) is now in two commits. GitGuardian's write-up of notebook leaks names this path: print statements, error messages and variable inspection display secrets that then persist in the notebook's JSON ([GitGuardian](https://blog.gitguardian.com/how-to-handle-secrets-in-jupyter-notebooks/)). The same holds for a data frame preview that shows customer rows: no secret scanner has a pattern for "a table that should not be here". In this small notebook 2,429 of 3,558 bytes are outputs; with real charts the proportion is far higher.

> **Unverified.** How often secrets leak through notebook outputs specifically. The report found mechanisms, not numbers.

**Problem 3: a line-based merge can produce a file that is not a notebook.**

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

Two people reran the same notebook on two branches. Git merged line by line, as it does for any text file, and wrote conflict markers into the middle of a JSON document. The file no longer parses; Jupyter cannot open it to let you resolve the conflict.

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

> **GitHub, not Git.** GitHub renders `.ipynb` files as static HTML. Its rich notebook diff is still the feature preview announced on 1 March 2023, in which you cannot comment on lines; no general-availability announcement was found ([changelog](https://github.blog/changelog/2023-03-01-feature-preview-rich-jupyter-notebook-diffs/)). **Unverified:** whether the redesigned "Files changed" page renders notebook rich diffs; the report did not check a signed-in interface. Treat it as a viewer, not as the basis of a review process.

## 28.4 A clean filter that strips outputs

**In one sentence.** A clean filter rewrites a notebook on its way into the repository so that the blob has no outputs, while the file in your working tree keeps them.

**Analogy.** A mail room that removes attachments from outgoing letters and files the plain letter. Your desk copy still has the attachments. Where it breaks: every desk has its own mail room, and a new employee's desk has none until somebody sets it up.

**Precisely.** [Chapter 14C: Stash internals, rerere, attributes and hooks](ch14c-stash-rerere-attributes-hooks.md), section 14C.8 defines filter drivers: `.gitattributes` names a driver for a path pattern, and `filter.<name>.clean` in the Git configuration defines the command, which reads the file on standard input and writes the cleaned form to standard output. That chapter showed a minimal notebook filter. This section goes further in the directions an ML team needs: what "required" changes, how `git status` behaves, what a clone has, and the form of the check that CI runs.

**The real tool.** nbstripout (0.9.1, February 2026) is the maintained implementation. From its documentation, not run here ([nbstripout](https://github.com/kynan/nbstripout/blob/main/README.md)):

```bash
nbstripout --install                              # filter into this clone's .git/config, attributes into .git/info/attributes
nbstripout --install --attributes .gitattributes  # attributes into a committed file instead
nbstripout --status                               # is the filter installed in this clone?
nbstripout --verify notebooks/*.ipynb             # exit non-zero if anything would be stripped: the CI form
```

Its README states the limitation that shapes everything below: there is no way to have Git set up the filter automatically when someone clones a repository, by design, so that a clone never executes arbitrary code.

**How such a tool works.** The core of `tools/nbstrip.py`, standard library only:

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

**See it.** The attribute is already committed in `.gitattributes`; the driver is defined in this clone's configuration:

<!-- snippet: ch28/notebook-filter/02-configure -->
```text
$ git check-attr filter -- notebooks/01-error-analysis.ipynb
notebooks/01-error-analysis.ipynb: filter: nbstrip
$ git config set filter.nbstrip.clean "python3 tools/nbstrip.py"
$ git config set filter.nbstrip.smudge cat
$ git config set filter.nbstrip.required true
```
<!-- /snippet -->

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

The file on disk has three outputs and 3,558 bytes. The blob has none and 967 bytes. The `checks:` line is the project's pre-commit hook reporting (section 28.10).

| Operation | Working tree | Index | HEAD | Current branch ref | Other refs and files in `.git` | Remote | GitHub |
|---|---|---|---|---|---|---|---|
| `git config set filter.nbstrip.clean ...` | unchanged | unchanged | unchanged | unchanged | `.git/config` gains the driver | unchanged | unchanged |
| `git add notebook.ipynb` with the filter | unchanged: outputs stay | entry points at a blob of the **cleaned** content | unchanged | unchanged | one new blob | unchanged | unchanged |
| `git add --renormalize .` | unchanged | every tracked file re-cleaned; entries change where the cleaned form differs | unchanged | unchanged | new blobs | unchanged | unchanged |
| `git restore <notebook>`, or `git switch` to a commit where the notebook differs | file rewritten from the **cleaned** blob (smudge is `cat`): local outputs are gone | updated | as usual | as usual | as usual | unchanged | unchanged |

The last row is the price: the outputs exist only in your working tree, and any command that rewrites the file from the repository discards them.

**Rerunning is no longer a change.**

<!-- snippet: ch28/notebook-filter/04-rerun -->
```text
# Rerun the notebook (simulated). The file changes; what Git would store does not:
$ grep -c 'not-a-real-key-0002' notebooks/01-error-analysis.ipynb
1
$ git status --short
$ git diff --stat
```
<!-- /snippet -->

The file contains the second run's printed key, and `git status` is silent, because Git compares the cleaned form of the file with the index. A change to the code of a cell still shows, as a one-line diff a reviewer can read:

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

**What `required` changes.** A filter is optional by default. The manual says a missing driver definition, or a driver that exits with an error, "is not an error but makes the filter a no-op passthru". For a filter whose purpose is to keep outputs out of history, a silent pass-through is the worst possible failure:

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

With `required = true`, `git add` fails with status 128 and nothing is staged. With it unset, the same three error lines appear, the exit status is 0, and the notebook is staged with its three outputs. nbstripout declares its filter required for this reason.

**What a clone has.**

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

The attribute travelled, because `.gitattributes` is a tracked file. The driver did not, because it lives in `.git/config`, and Git never copies configuration from a clone source: if it did, cloning a repository would let its author run commands on your machine. `required = true` did not help either, since that setting is part of the same missing configuration. Asha's notebook went in with outputs and nothing warned her.

**The check that does travel.**

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

`--verify` strips each committed notebook in memory and fails if the result differs from the file. On a fresh checkout the files are the blobs, so this is a check of what is in history. It fails on Asha's commit and passes on the one before. Run as a required check, it is the control; the filter on each laptop is a convenience that keeps people from tripping it.

**In production.** Stripping outputs is also a data-protection control, as the report notes: outputs hold query results and personal data that no secret-scanning pattern matches. A team that needs some outputs in review (a chart that is the result) has three honest options: commit them deliberately with a tool that supports review of outputs (section 28.5), export the figure to a tracked report file, or keep the outputs in the experiment tracker and link the run.

## 28.5 nbdime, jupytext, ReviewNB: tools that complement the filter

The maintained tools are complementary, not alternatives. Commands are from each tool's documentation and are not run here.

| Tool (version on 1 October 2026) | What it controls | Mechanism in Git terms |
|---|---|---|
| nbstripout (0.9.1) | what enters history | a clean filter, section 28.4 |
| nbdime (4.0.4) | how notebooks are diffed and merged locally | a diff driver, a merge driver and a merge tool |
| jupytext (1.19.5) | what gets reviewed | pairs the notebook with a plain-text file |
| ReviewNB (commercial GitHub app) | review of notebooks **with** outputs | comments on rendered notebook diffs in pull requests |

**nbdime** understands the notebook structure, so it can show a cell-level diff and can merge two reruns by resolving generated values such as execution counters instead of writing conflict markers into JSON ([nbdime](https://nbdime.readthedocs.io/en/latest/), [Git integration](https://nbdime.readthedocs.io/en/latest/vcs.html)):

```bash
nbdime config-git --enable            # register the diff driver, merge driver and merge tool for this repository
nbdiff-web main feature notebook.ipynb
git mergetool --tool nbdime -- *.ipynb
```

The `.gitattributes` lines it relies on are `*.ipynb diff=jupyternotebook` and `*.ipynb merge=jupyternotebook`. Like every driver, these are definitions in each clone's configuration (Chapter 14C, sections 14C.6 and 14C.7): a colleague who has not run the command gets Git's line-based behavior, with no warning.

**jupytext** takes the other road: do not review the `.ipynb` at all ([jupytext](https://github.com/jupytext/jupytext/blob/main/README.md)).

```bash
jupytext --set-formats ipynb,py:percent notebook.ipynb   # pair the notebook with notebook.py
jupytext --sync notebook.py                              # bring both files up to date from the newer one
jupytext --to ipynb notebook.py                          # rebuild the notebook from the text file
```

The `.py` file contains only the cell inputs, so a pull request shows an ordinary Python diff. The README's own recipe is to commit the text file and, unless you want outputs versioned, to keep the `.ipynb` out of version control.

**Choosing.**

| Situation | Reasonable choice |
|---|---|
| Notebooks are exploration; nobody reviews outputs | strip outputs (nbstripout), verify in CI |
| Notebooks contain logic that is reviewed like code | pair with jupytext and review the `.py`; ignore or strip the `.ipynb` |
| Outputs are the deliverable and must be discussed | commit them on purpose, and use a tool built to review them (ReviewNB, or nbdime's web viewers locally) |
| Notebook logic keeps growing | move it into the package under `src/` and import it; the notebook becomes a thin caller |

The last row is the durable fix. A function in `src/docqa/` has tests, a diff and a blame history. A cell has none of them.

## 28.6 Data and model versioning: Git holds the reference, another system holds the bytes

**In one sentence.** You version a large file by committing a small file that names it by checksum, and by keeping the bytes in a store that is addressed by that checksum.

**Analogy.** A coat-check ticket. The ticket is small and travels with you; the coat stays in the cloakroom. The analogy breaks in two places that matter: this ticket is derived from the coat (it is a hash of the contents, so a different coat can never be handed back for it), and a ticket is worthless if the cloakroom has been emptied.

**Precisely.** Every tool in this section is a variation on one pattern, which you met as Git LFS in [Chapter 22: Git LFS](ch22-git-lfs.md):

1. Compute a cryptographic hash of the file.
2. Store the file outside Git under that hash (content-addressed storage).
3. Commit a small pointer that records the hash and the size.
4. Tell Git to ignore the real file, or let a filter swap pointer and file.

Git then versions the pointer: `git log`, `git diff`, branches, tags and pull requests all work on it, and "which data did this commit use" has an exact answer.

**See it.** `tools/dataref.py` is that pattern in about a hundred lines of standard-library Python. The store is a directory beside the repository; in production it would be a bucket.

<!-- snippet: ch28/data-pointer/01-add -->
```text
$ wc -l < data/raw/tickets.csv
      11
$ git status --short --ignored data
!! data/raw/
$ python3 tools/dataref.py add data/raw/tickets.csv
stored data/raw/tickets.csv as sha256:2226b23c455b (432 bytes)
commit the pointer: git add data/raw/tickets.csv.ref
$ cat data/raw/tickets.csv.ref
{
  "path": "tickets.csv",
  "sha256": "2226b23c455b63565c71f01555c41bdd3661598f70cd2c989b0ddcd0164a898e",
  "size": 432
}
$ git status --short data
?? data/raw/
$ git add data/raw/tickets.csv.ref && git commit -q -m "Version the ticket data set by reference"
checks: 1 file version(s) examined, 0 problem(s)
```
<!-- /snippet -->

The data file was ignored before and stays ignored (`!! data/raw/` in the first status). What becomes visible to Git is the pointer: five lines of JSON for a file of any size.

**Picture.**

```text
   Git repository (cloned by everyone)            data store (a bucket; access-controlled)
  +-------------------------------------+        +---------------------------------------+
  | data/raw/tickets.csv.ref            |        | sha256/22/26b23c45...  (432 bytes)    |
  |   { "sha256": "2226b23c45...",      | -----> | sha256/4e/fbc43184...  (606 bytes)    |
  |     "size": 432 }                   |        |                                       |
  | .gitignore:  /data/**  !*.ref       |        | one object per version, named by hash |
  +-------------------------------------+        +---------------------------------------+
        working tree: data/raw/tickets.csv is present, ignored, and checked against the pointer
```

**A new version of the data is a one-line diff.**

<!-- snippet: ch28/data-pointer/02-new-version -->
```text
# Four labelled tickets arrive. The data file changes; Git sees nothing until the pointer changes:
$ git status --short
$ python3 tools/dataref.py verify
differs  data/raw/tickets.csv  (pointer sha256:2226b23c455b)
[exit status: 1]
$ python3 tools/dataref.py add data/raw/tickets.csv
stored data/raw/tickets.csv as sha256:4efbc43184d3 (606 bytes)
commit the pointer: git add data/raw/tickets.csv.ref
$ git diff
diff --git a/data/raw/tickets.csv.ref b/data/raw/tickets.csv.ref
index e27856a..0dd411a 100644
--- a/data/raw/tickets.csv.ref
+++ b/data/raw/tickets.csv.ref
@@ -1,5 +1,5 @@
 {
   "path": "tickets.csv",
-  "sha256": "2226b23c455b63565c71f01555c41bdd3661598f70cd2c989b0ddcd0164a898e",
-  "size": 432
+  "sha256": "4efbc43184d3a7e7fbed75dd9f07d1c89633dd493cbb53392340d5541a9a0681",
+  "size": 606
 }
$ git commit -q -am "Add four labelled tickets to the data set"
checks: 1 file version(s) examined, 0 problem(s)
```
<!-- /snippet -->

Read the first two commands together. Four rows were appended to the data, and `git status` printed nothing: Git does not watch an ignored file. The tool's own `verify` reports the mismatch. This is the central weakness of versioning by reference, and Lab 33.2 turns it into a failure scenario: **the pointer and the file can disagree, and Git will not tell you.**

**Going back is two steps.**

<!-- snippet: ch28/data-pointer/04-time-travel -->
```text
# Going back is two steps: Git moves the pointer, the tool moves the bytes.
$ git switch -q --detach HEAD~1
$ python3 tools/dataref.py verify
differs  data/raw/tickets.csv  (pointer sha256:2226b23c455b)
[exit status: 1]
$ python3 tools/dataref.py checkout
restored    data/raw/tickets.csv from sha256:2226b23c455b
$ wc -l < data/raw/tickets.csv
      11
$ git switch -q main && python3 tools/dataref.py checkout
restored    data/raw/tickets.csv from sha256:4efbc43184d3
```
<!-- /snippet -->

Git moved the pointer; the working file still held the newer data until the tool restored the version the pointer names. DVC has the same two steps (`git checkout`, then `dvc checkout`). Git LFS hides the second step inside a smudge filter, which is more convenient and is why a clone without the LFS client silently gets pointers.

**A clone has pointers, not data; and the store is a dependency.**

<!-- snippet: ch28/data-pointer/05-clone -->
```text
$ git clone -q . ../docqa-ravi && cd ../docqa-ravi
$ ls data/raw
tickets.csv.ref
$ python3 tools/dataref.py checkout
restored    data/raw/tickets.csv from sha256:4efbc43184d3
$ python3 tools/dataref.py verify
ok       data/raw/tickets.csv  (pointer sha256:4efbc43184d3)
```
<!-- /snippet -->

<!-- snippet: ch28/data-pointer/06-store-is-the-risk -->
```text
# The pointer is only as good as the store behind it:
$ rm -r ../datastore/sha256 && rm data/raw/tickets.csv
$ python3 tools/dataref.py checkout
NOT IN STORE data/raw/tickets.csv sha256:4efbc43184d3
[exit status: 1]
```
<!-- /snippet -->

A pointer whose object is gone identifies a data set precisely and cannot produce it. The store needs what the repository has: backups, access control, and a retention rule that never deletes an object some commit still points to.

**The real tools.** The table is the report's, with its dates and flags.

| Tool | Status on 1 October 2026 | Mechanism | When it fits, and caveats |
|---|---|---|---|
| Git LFS | client 3.8.0; GitHub caps a file at 2 to 5 GB by plan; metered billing ([LFS documentation](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage)) | a three-line pointer in Git, swapped by a required filter; objects in LFS storage | a modest number of mid-sized, rarely changing binaries. Wrong when files exceed the cap, change often (each version is stored whole), must be deletable, or when CI and contributors lack the client (the report's inference; Chapter 22, section 22.13) |
| DVC | 3.67.1 (31 March 2026); Apache-2.0; stewardship moved to lakeFS on 18 November 2025 ([DVC blog](https://dvc.org/blog/dvc-joins-lakefs-your-questions-answered/), [releases](https://github.com/treeverse/dvc/releases)) | a `.dvc` metafile per tracked path; the data path is added to `.gitignore`; data moves with `dvc push` and `dvc pull` | Git-based versioning for small to medium projects. Maintained; no release in the six months after March 2026, and its roadmap is unstated |
| lakeFS | v1.88.0; **Business Source License from v1.87.0** (22 September 2026); earlier releases remain Apache 2.0 ([lakeFS blog](https://lakefs.io/blog/lakefs-business-source-license/)) | Git-like branches over object storage | platform-scale data. Do not call it open source without the version caveat; read the licence text before embedding it in a product |
| git-annex | 10.20260901 ([git-annex](https://git-annex.branchable.com/)) | manages large files with Git without storing their contents in Git | a niche alternative |
| Hugging Face Hub | all repositories migrated from Git LFS storage to Xet by October 2025; the LFS pointer format is kept for compatibility ([Hugging Face](https://huggingface.co/blog/huggingface-hub-v1), [legacy LFS](https://huggingface.co/docs/hub/en/xet/legacy-git-lfs)) | Git repositories whose large files are routed through `.gitattributes`; byte-level deduplication | pin what you download |
| Model registries | MLflow 3.16.1; W&B SDK 0.30.0, documentation now under docs.coreweave.com ([MLflow](https://mlflow.org/docs/latest/ml/model-registry/), [W&B](https://docs.coreweave.com/models/artifacts)) | versioned models with lineage to the producing run; mutable aliases | record the Git commit beside the model version |

> **Unverified.** The Hugging Face "all repositories migrated" claim dates from October 2025 and was not independently verified for 2026. No statement of DVC's roadmap was found. Both flags are carried from the report.

**DVC, from its documentation** ([get started](https://doc.dvc.org/start)); not run here, because DVC is not installed. In a repository where DVC has been initialized as the guide describes:

```bash
dvc add data/data.xml                       # writes data/data.xml.dvc and adds the data path to data/.gitignore
git add data/data.xml.dvc data/.gitignore   # Git versions the metafile, not the data
git commit -m "Add raw data"
dvc remote add -d myremote <location>       # where the bytes go (a bucket or a directory)
dvc push                                    # upload the data
dvc pull                                    # in another clone: download what the metafiles name
git checkout <revision>                     # move the metafile ...
dvc checkout                                # ... then make the data match it
```

Compare each line with the transcript above: `dvc add` is `dataref.py add` plus the ignore rule; the `.dvc` metafile is the `.ref` file (the guide shows it holding an `md5` and a `path`); `dvc checkout` is `dataref.py checkout`. The DVC guide says of itself that DVC "is technically not a version control system": it manipulates metafiles that Git versions.

**Pinning a model from a hub.** A model ID such as `org/name` names whatever the publisher's default branch points at today. The Hugging Face download guide documents a `revision` parameter that accepts a branch, a tag or a commit hash, and says a commit hash must be the full-length hash, not a seven-character abbreviation ([download guide](https://huggingface.co/docs/huggingface_hub/guides/download)). Not run here:

```python
from huggingface_hub import snapshot_download

snapshot_download(repo_id="example-org/ticket-embedder",
                  revision="<the full-length commit hash you evaluated>",
                  allow_patterns=["*.safetensors", "*.json"])
```

A branch or tag in `revision` is a moving reference, exactly as a Git branch is. Commit the hash you evaluated; that line of configuration is the model's pointer file.

**In production.** Registry aliases such as `champion` are mutable by design, which is what makes promotion a one-step operation and what makes an alias useless as a record. Deploy by alias if you like; log the resolved version number and the Git commit of the training code beside it.

## 28.7 Reproducibility: the commit alone does not identify what ran

**In one sentence.** A result is identified by the commit, the state of the working tree relative to that commit, the data and model versions, the resolved configuration and the environment; record all of them or you have recorded a guess.

**Analogy.** A chain of custody. A sealed evidence bag with a label is evidence; an open bag with the same label is not. The commit ID is the label; the dirty flag says whether the bag was open. Where it breaks: unlike a seal, a dirty tree can be reconstructed exactly if you also keep the patch.

**Precisely.** The report's list of what must be recorded together: the Git commit and whether the tree was dirty; a committed lock file; an immutable container reference; the resolved configuration; the data and model versions. It also records that the tools capture less than people assume:

- **MLflow.** The classic run context sets `mlflow.source.git.commit`, the branch and the repository URL when the entry point is inside a Git repository, and does not inspect or record uncommitted changes. A newer, opt-in function marked experimental records the dirty state and the diff ([system tags](https://mlflow.org/docs/latest/ml/tracking/tracking-api/), [git context source](https://github.com/mlflow/mlflow/blob/master/mlflow/tracking/context/git_context.py), [genai versioning source](https://github.com/mlflow/mlflow/blob/master/mlflow/genai/git_versioning/git_info.py)).
- **Weights & Biases.** It generates a patch of uncommitted changes when code is logged, but code saving is disabled by default for all teams ([code saving](https://docs.coreweave.com/models/app/features/panels/code)).
- **Hydra.** It writes the resolved configuration and the command-line overrides into a `.hydra` directory for every run ([Hydra](https://hydra.cc/docs/tutorials/basic/running_your_app/working_directory/)).

> **Unverified.** The report flags a conflict about MLflow's branch tag: the documentation table says it is set for MLflow Projects only, the source code sets it for any run inside a repository, and the source is the more reliable description. The opt-in function is described from source code, not from a documentation page. W&B's exact default for commit capture when code saving is off was not tested, and a bug report about missing patch files exists, so verify capture instead of assuming it. Hydra's behavior was read from the development documentation, not re-verified against release 1.3.7.

The consequence, in the report's words: with classic tracking, two different code states can share one commit ID.

**See it: a function that records the state.** Sixteen lines of standard library:

<!-- snippet: ch28/run-record/01-function -->
```text
$ sed -n '19,34p' tools/runinfo.py
    """Return a dict that identifies the code state of the current repository."""
    commit = _git("rev-parse", "HEAD").decode().strip()
    # Porcelain v1 with NUL separators: stable across Git versions and safe for odd file names.
    status = [e for e in _git("status", "--porcelain=v1", "-z", "--untracked-files=all").decode().split("\0") if e]
    tracked = [e for e in status if not e.startswith("??")]
    untracked = [e[3:] for e in status if e.startswith("??")]
    diff = _git("diff", "HEAD", "--binary") if tracked else b""
    return {
        "commit": commit,
        "describe": _git("describe", "--always", "--dirty", "--tags").decode().strip(),
        "dirty": bool(tracked),
        "changed": tracked,
        "untracked": untracked,
        "diff_sha256": hashlib.sha256(diff).hexdigest() if diff else None,
    }
```
<!-- /snippet -->

Four Git commands do the work. `git rev-parse HEAD` gives the commit. `git status --porcelain=v1 -z` gives a stable, machine-readable list of what differs; entries starting with `??` are untracked files. `git diff HEAD --binary` is the complete uncommitted change to tracked files, and its SHA-256 identifies that change. `git describe --always --dirty --tags` gives a human-readable name.

<!-- snippet: ch28/run-record/02-clean -->
```text
$ python3 tools/runinfo.py
{
  "changed": [],
  "commit": "aa18ad2fb32ebcc4c1603d60d9aa1b6f3540b80e",
  "describe": "v0.1.0",
  "diff_sha256": null,
  "dirty": false,
  "untracked": []
}
```
<!-- /snippet -->

**A recorded run.** The evaluation script calls the function and writes the record beside the metrics:

<!-- snippet: ch28/run-record/03-run -->
```text
$ python3 evals/run_eval.py baseline
run baseline: accuracy 0.8000 on 10 examples (commit aa18ad2)
$ cat runs/baseline/run.json
{
  "code": {
    "changed": [],
    "commit": "aa18ad2fb32ebcc4c1603d60d9aa1b6f3540b80e",
    "describe": "v0.1.0",
    "diff_sha256": null,
    "dirty": false,
    "untracked": []
  },
  "config_sha256": "b315d1f3d160e1022d366b19e4189868df102c829bf0c826b85473da1045e1fa",
  "data": {
    "path": "data/raw/tickets.csv",
    "sha256": "2226b23c455b63565c71f01555c41bdd3661598f70cd2c989b0ddcd0164a898e"
  },
  "lock_sha256": "085aa13c19c2ff263dc4c94771b99cb7dc6ec535f40dded48e1b6c54f06980cb",
  "metrics": {
    "accuracy": 0.8,
    "examples": 10
  },
  "resolved_config": {
    "data": "data/raw/tickets.csv",
    "default": "general",
    "keywords": {
      "billing": [
        "invoice",
        "refund",
        "charged"
      ],
      "technical": [
        "error",
        "crash",
        "timeout"
      ]
    }
  }
}
```
<!-- /snippet -->

Five identifiers in one file: the commit `aa18ad2` with `dirty: false`; the checksum of the data actually read (compare it with the pointer in section 28.6); a hash of the lock file; a hash of the configuration; and the resolved configuration itself, so that the record can be read without checking anything out.

**Two results, one commit.** Now try an idea without committing it:

<!-- snippet: ch28/run-record/04-dirty -->
```text
# Try an idea without committing it: one more billing keyword.
$ sed -i.bak 's/"charged"/"charged", "card"/' configs/eval.json && rm configs/eval.json.bak
$ git status --short
 M configs/eval.json
$ python3 evals/run_eval.py tuned
refusing a tracked run from a dirty tree:  M configs/eval.json
[exit status: 1]
$ python3 evals/run_eval.py tuned --allow-dirty
run tuned: accuracy 0.9000 on 10 examples (commit aa18ad2, dirty)
```
<!-- /snippet -->

The script refuses a tracked run from a dirty tree, which is the first defensible policy. With `--allow-dirty` it runs and records what it can:

<!-- snippet: ch28/run-record/05-same-commit -->
```text
# Two results, one commit ID. Only the dirty flag and the diff hash tell them apart:
$ grep -h -e "\"commit\"" -e "\"dirty\"" -e "\"diff_sha256\"" -e "\"accuracy\"" runs/baseline/run.json runs/tuned/run.json
    "commit": "aa18ad2fb32ebcc4c1603d60d9aa1b6f3540b80e",
    "diff_sha256": null,
    "dirty": false,
    "accuracy": 0.8,
    "commit": "aa18ad2fb32ebcc4c1603d60d9aa1b6f3540b80e",
    "diff_sha256": "71195d1fdbe1681494c2eca7772d5753adaeb9e886818b92607d602d432790e7",
    "dirty": true,
    "accuracy": 0.9,
$ ls runs/tuned
metrics.json
run.json
uncommitted.patch
$ git diff HEAD --binary | shasum -a 256
71195d1fdbe1681494c2eca7772d5753adaeb9e886818b92607d602d432790e7  -
```
<!-- /snippet -->

Accuracy 0.8 and accuracy 0.9, both "at commit `aa18ad2`". A tracker that stores only the commit shows two runs of the same code with different results. This record tells them apart: `dirty: true`, a hash of the uncommitted diff, and the diff itself saved as `uncommitted.patch`. The last command proves the hash is of that diff. That is the second defensible policy: if dirty runs are allowed, log the status and the diff as artifacts. Lab 33.3 reproduces the 0.9 from exactly these three things.

```text
Observed behavior : checking out the commit named by a run gives a different metric.
Git state         : the commit is intact. The run's working tree had a modified tracked file.
Mechanism         : "git rev-parse HEAD" names the last commit; it says nothing about the
                    index or the working tree. Python imported the files on disk.
Root cause        : the tracker recorded HEAD and not the difference between HEAD and what ran.
Why Git does this : a commit is a snapshot that was taken; uncommitted work is, by definition,
                    in no snapshot.
Correct fix       : if the patch was saved, apply it to the commit and rerun (Lab 33.3). If
                    not, the result cannot be reproduced; say so and rerun from a commit.
Prevention        : refuse tracked runs from a dirty tree, or record status and diff; treat
                    untracked files the same way.
```

**Untracked files are a third state.**

<!-- snippet: ch28/run-record/06-untracked -->
```text
# An untracked file is not in "git diff", and it can still change what runs:
$ printf 'KEYWORD_OVERRIDES = {}\n' > src/docqa/local_settings.py
$ git status --short
?? src/docqa/local_settings.py
$ python3 tools/runinfo.py | grep -e dirty -e untracked -A1
  "dirty": false,
  "untracked": [
    "src/docqa/local_settings.py"
$ python3 tools/runinfo.py --require-clean
refusing to run: the working tree does not match commit aa18ad2
  untracked: src/docqa/local_settings.py
[exit status: 1]
```
<!-- /snippet -->

`dirty` is false, because no tracked file changed, and `git diff HEAD` is empty. Yet a new module on the import path can change behavior. The function reports untracked files separately and `--require-clean` refuses both. The MLflow opt-in function described above does not count untracked files as dirty, according to the report's reading of its source.

## 28.8 Lock files, container digests and resolved configuration

The record of section 28.7 contains hashes of three things that live in the repository. Each has a rule.

**Lock files are committed.** A dependency range such as `transformers>=4` is resolved to exact versions at install time, so two installs a month apart differ. uv (0.12.21) documents `uv.lock` as a cross-platform lock file that should be checked into version control, and `--locked` as the option that raises an error instead of updating a lock file that is out of date ([project layout](https://docs.astral.sh/uv/concepts/projects/layout/), [locking and syncing](https://docs.astral.sh/uv/concepts/projects/sync/)). GitHub's Python ignore template recommends committing lock files for applications ([template](https://github.com/github/gitignore/blob/main/Python.gitignore)). From the uv documentation, not run here:

```bash
uv lock            # resolve and write uv.lock; commit the result
uv sync --locked   # install exactly what uv.lock says; fail if it is out of date (the CI form)
```

A lock file is generated, and it is still committed, because it is an input to every later build. The test for "generated files do not belong in Git" is whether the file can be regenerated identically from what is in Git; a lock file cannot, since the package index changes.

**Container images are pinned by digest.** An image tag is a mutable reference, like a branch: the publisher can move it. Docker's guidance is that pinning to a digest guarantees the same image, at the price of opting out of automatic fixes, which it suggests offsetting with Dependabot updating the pin on a schedule ([Docker best practices](https://docs.docker.com/build/building/best-practices/)). The parallel with Git is exact: tag is to digest as branch is to commit ID.

**Configuration is recorded resolved.** A configuration built from defaults, files, environment variables and command-line overrides exists in its final form only at run time. Record that final form with the run, as `resolved_config` does above and as Hydra does in `.hydra/config.yaml`.

**Versions derived from tags need the tags.** `git describe` names a commit by the most recent reachable annotated tag, and packaging plugins such as setuptools-scm (10.3.4) and hatch-vcs (0.5.0) derive the package version from it. In CI the default `actions/checkout` fetches one commit and no tags, so the derived version fails or falls back; set `fetch-depth: 0` in the jobs that need it ([git-describe](https://git-scm.com/docs/git-describe), [setuptools-scm](https://github.com/pypa/setuptools-scm/blob/main/docs/index.md)).

| Identifier | Mutable reference (do not record) | Immutable identifier (record) |
|---|---|---|
| Code | branch name, `HEAD` | full commit ID, plus dirty flag and diff hash |
| Dependencies | version ranges in `pyproject.toml` | the committed lock file, or its hash |
| Environment | image tag | image digest |
| Data | file path, "latest" | checksum from the pointer file |
| Model | model name, registry alias, hub branch | registry version number; hub commit hash |
| Configuration | defaults plus overrides | the resolved configuration |

## 28.9 `.gitignore` and `.gitattributes` for ML projects

**In one sentence.** Ignore rules keep generated and large files from being added by accident, attributes say how tracked files are converted and merged, and neither is a security control.

> **Assembled, not authoritative.** The report found no authoritative, maintained `.gitignore` template for ML projects. GitHub's Python template covers interpreter, packaging, environment and tool caches and contains nothing ML-specific. The file below is assembled from that template and from each tool's documentation of where it writes output. Read it as a starting point and adjust it to the tools you run.

<!-- snippet: ch28/project-skeleton/06-ignore-file -->
```text
$ cat .gitignore
# Python (a subset of GitHub's Python template)
__pycache__/
*.py[cod]
.venv/
.pytest_cache/
.ruff_cache/
build/
dist/
*.egg-info/

# Secrets and machine-local settings
.env
.env.*
!.env.example

# Data is versioned by reference: only pointers and the README are tracked
/data/**
!/data/**/
!/data/**/*.ref
!/data/README.md

# Model weights live in the model store, whatever directory they land in
/models/**
!/models/README.md
!/models/*.ref
*.pt
*.pth
*.ckpt
*.safetensors
*.onnx
*.gguf

# Experiment trackers and run outputs
/runs/
wandb/
mlruns/
mlflow.db
outputs/
multirun/

# Notebook autosave copies
.ipynb_checkpoints/
```
<!-- /snippet -->

Why each group exists: the data directory, because data is versioned by reference (Cookiecutter Data Science's generated ignore file likewise ignores `/data/`); weight formats, because one stray `git add .` after training would otherwise commit a checkpoint; `wandb/`, `mlruns/` and `mlflow.db`, because the trackers write there by default; `outputs/` and `multirun/`, because Hydra creates a directory per run; `.env`, because that is where local credentials go. Editor and operating-system files (`.DS_Store`, `.idea/`) are deliberately absent: they belong in each developer's global ignore file (`core.excludesFile`), not in every project.

**Which rule matched?** `git check-ignore -v` answers with the file, line and pattern:

<!-- snippet: ch28/ml-ignore/01-which-rule -->
```text
$ git check-ignore -v data/raw/tickets.csv data/processed/train.parquet models/v1/model.safetensors checkpoints/epoch-3.ckpt runs/r1/metrics.json wandb/debug.log .env
.gitignore:17:/data/**	data/raw/tickets.csv
.gitignore:17:/data/**	data/processed/train.parquet
.gitignore:23:/models/**	models/v1/model.safetensors
.gitignore:28:*.ckpt	checkpoints/epoch-3.ckpt
.gitignore:34:/runs/	runs/r1/metrics.json
.gitignore:35:wandb/	wandb/debug.log
.gitignore:12:.env	.env
# The pointer, the README and the example file are not ignored: no output, exit status 1.
$ git check-ignore data/raw/tickets.csv.ref data/README.md .env.example
[exit status: 1]
# With -v, Git names the last matching pattern even when it is a negation (it starts with "!"):
$ git check-ignore -v data/raw/tickets.csv.ref data/README.md .env.example
.gitignore:19:!/data/**/*.ref	data/raw/tickets.csv.ref
.gitignore:20:!/data/README.md	data/README.md
.gitignore:14:!.env.example	.env.example
```
<!-- /snippet -->

The data rules use a pattern worth understanding. `/data/**` ignores everything below `data/`. `!/data/**/` re-includes the directories, which is necessary because Git does not look inside an ignored directory, so no later rule could re-include a file in it. `!/data/**/*.ref` then re-includes the pointer files. Note the last command: with `-v`, `check-ignore` prints the matching pattern even when it is a negation, and exits 0; a line whose pattern starts with `!` means "not ignored".

**Rule 1: ignore patterns never affect files that are already tracked.**

<!-- snippet: ch28/ml-ignore/03-tracked-before-rule -->
```text
# A checkpoint was committed before anybody wrote a rule for it:
$ git add classifier.ckpt && git commit -q -m "Add trained classifier"
$ printf '*.ckpt\n' > .gitignore && git add .gitignore && git commit -q -m 'Ignore checkpoints'
$ git ls-files
.gitattributes
.gitignore
README.md
classifier.ckpt
pyproject.toml
requirements.lock
src/docqa/__init__.py
src/docqa/classify.py
tests/test_classify.py
$ git check-ignore -v classifier.ckpt
[exit status: 1]
$ git check-ignore -v --no-index classifier.ckpt
.gitignore:1:*.ckpt	classifier.ckpt
# The rule matches the path, and Git keeps tracking the file: retraining shows up as a change.
$ git status --short
 M classifier.ckpt
```
<!-- /snippet -->

The pattern matches the path (`--no-index` shows that), and Git goes on tracking the file, because the manual defines ignore files as specifying "intentionally untracked files": the index decides what is tracked, not `.gitignore`.

<!-- snippet: ch28/ml-ignore/04-untrack -->
```text
$ git rm --cached classifier.ckpt
rm 'classifier.ckpt'
$ git commit -q -m "Stop tracking the checkpoint"
$ git status --short --ignored
!! classifier.ckpt
# Untracked from now on. History is unchanged: every clone still downloads the blob.
$ git log --oneline -- classifier.ckpt
04154c0 Stop tracking the checkpoint
a4fc927 Add trained classifier
$ git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | grep ckpt
blob 262144 classifier.ckpt
```
<!-- /snippet -->

🟡 CAUTION: `git rm --cached <path>` removes the path from the index and leaves the file on disk; the next commit records a deletion, and a colleague who pulls that commit has the file deleted from their working tree. And the history is untouched: the 262,144-byte blob is still reachable, so every clone still downloads it. Removing it from history is a rewrite with `git filter-repo`, with everything that implies for a shared repository (Chapter 21B: Repository security; Chapter 30: Incident response). For a secret, rotation comes first.

**Rule 2: drivers are named in `.gitattributes` and defined in configuration.**

<!-- snippet: ch28/project-skeleton/05-attributes -->
```text
$ cat .gitattributes
# Line endings: normalize text to LF in the repository on every platform
* text=auto
*.sh text eol=lf

# Notebooks enter the repository without outputs (driver: tools/nbstrip.py, see README)
*.ipynb filter=nbstrip

# Pointer files must never be converted or merged line by line
*.ref text eol=lf merge=binary
$ git check-attr -a notebooks/01-error-analysis.ipynb data/raw/tickets.csv.ref
notebooks/01-error-analysis.ipynb: text: auto
notebooks/01-error-analysis.ipynb: filter: nbstrip
data/raw/tickets.csv.ref: merge: binary
data/raw/tickets.csv.ref: text: set
data/raw/tickets.csv.ref: eol: lf
```
<!-- /snippet -->

The attributes file, like the ignore file, is assembled. Three decisions are in it. `* text=auto` normalizes line endings in the repository for every contributor; the manual's way to apply it to an existing repository is `git add --renormalize .` (Chapter 14C, section 14C.5). `*.ipynb filter=nbstrip` names the notebook filter; a committed attribute that names a driver nobody configured is a silent no-op, or a hard failure when the filter is required, which is section 28.4 in one sentence. And `merge=binary` on pointer files tells Git never to combine two pointers line by line: a pointer whose hash came from one side and whose size came from the other names nothing.

**Rule 3: an ignore file is not a security control.** It prevents accidents by people who use `git add` without `-f`. It does nothing about a file committed before the rule existed, a file added with `--force`, or a secret pasted into a tracked file.

## 28.10 The pre-commit framework, and why local hooks must be backed by CI

**In one sentence.** A hook gives the author feedback in seconds; only a check that runs where the author cannot skip it is a control.

**The framework.** pre-commit (4.6.2, August 2026) manages hooks declared in a committed file: `pre-commit install` installs the Git hook into the clone, `pre-commit run --all-files` is the documented CI usage, and `rev` must be an immutable tag or commit ([pre-commit](https://pre-commit.com/)). A typical configuration for an ML repository, assembled from the tools' READMEs with the versions in the report, not run here:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v6.0.0
    hooks:
      - id: check-added-large-files    # default threshold 500 kB
      - id: detect-private-key
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.16.9
    hooks:
      - id: ruff-check
      - id: ruff-format
  - repo: https://github.com/kynan/nbstripout
    rev: 0.9.1
    hooks:
      - id: nbstripout
```

Add one secret scanner. The report notes that the gitleaks README now describes the project as feature complete, with future releases limited to security patches, so check the state of whichever scanner you choose. prek (v0.5.4) is a Rust reimplementation that reads the same configuration ([prek](https://github.com/j178/prek/blob/master/README.md)); the report collected no benchmarks for it.

```bash
pre-commit install            # once per clone: writes .git/hooks/pre-commit
pre-commit run --all-files    # what CI runs
```

**Why "once per clone" is the whole problem.** The report lists the ways a local hook fails open: hooks are not installed by cloning, they are skipped with one flag, and they are bypassed by commits made through the web interface, the API, or an agent's own Git client. Chapter 14C, sections 14C.11 to 14C.13 give the mechanics. Here is each failure with the checks of this project, which are a standard-library stand-in for the hooks above (`tools/checks.py`: file size, private keys, environment files, weight files, notebooks with outputs).

<!-- snippet: ch28/hooks-vs-ci/01-hook-blocks -->
```text
$ cat hooks/pre-commit
#!/bin/sh
# Shared pre-commit hook. Enable it once per clone: git config set core.hooksPath hooks
exec python3 tools/checks.py --staged
$ git config get core.hooksPath
hooks
$ git switch -q -c feature/deploy-script
$ mkdir deploy && printf -- '-----BEGIN OPENSSH PRIVATE KEY-----\nnot-a-real-key\n-----END OPENSSH PRIVATE KEY-----\n' > deploy/id_deploy
$ git add deploy
$ git commit -m "Add deploy key for the staging box"
index deploy/id_deploy: contains a private key
checks: 1 file version(s) examined, 1 problem(s)
[exit status: 1]
```
<!-- /snippet -->

The hook did its job: the commit was refused before the key reached any history.

<!-- snippet: ch28/hooks-vs-ci/02-no-verify -->
```text
# One flag skips the hook:
$ git commit -q --no-verify -m "Add deploy key for the staging box"
[exit status: 0]
$ git push -q -u origin feature/deploy-script
```
<!-- /snippet -->

`--no-verify` is not a loophole; it is a documented option, and there are honest uses for it. A control that the controlled person can switch off is not a control.

<!-- snippet: ch28/hooks-vs-ci/03-clone-has-no-hook -->
```text
$ git clone -q ../server.git ../docqa-asha && cd ../docqa-asha
$ git config get core.hooksPath
[exit status: 1]
$ git switch -q -c feature/eval-dump
$ wc -c < evals/dump.json
  900011
$ git add evals/dump.json && git commit -q -m "Add evaluation dump for debugging"
$ git push -q -u origin feature/eval-dump
```
<!-- /snippet -->

Asha never skipped anything. Her clone has no `core.hooksPath`, because configuration does not travel, so no hook ran. This is the answer to the fourth question of section 28.1.

**The same checks, where they cannot be skipped.** `ci/check.sh` runs the identical script over what was pushed:

<!-- snippet: ch28/hooks-vs-ci/04-ci -->
```text
# CI checks out each pushed branch and runs the same script over the range it adds:
$ cat ci/check.sh
#!/bin/sh
# Everything CI runs, runnable locally: sh ci/check.sh <base>
# <base> is the commit the branch started from (default: origin/main).
status=0
# 1. Every file version the branch adds, including ones a later commit removed again.
python3 tools/checks.py --range "${1:-origin/main}..HEAD" || status=1
# 2. The whole snapshot that would be merged.
python3 tools/checks.py --tree HEAD || status=1
if python3 -m unittest discover -s tests > /dev/null 2>&1; then echo "tests: ok"; else echo "tests: FAILED"; status=1; fi
exit $status
$ sh ci/check.sh origin/main
27e79a4 evals/dump.json: larger than 500000 bytes (900011)
checks: 1 file version(s) examined, 1 problem(s)
HEAD evals/dump.json: larger than 500000 bytes (900011)
checks: 25 file version(s) examined, 1 problem(s)
tests: ok
[exit status: 1]
$ git switch -q feature/deploy-script
$ sh ci/check.sh origin/main
8ca3417 deploy/id_deploy: contains a private key
checks: 1 file version(s) examined, 1 problem(s)
HEAD deploy/id_deploy: contains a private key
checks: 25 file version(s) examined, 1 problem(s)
tests: ok
[exit status: 1]
$ git switch -q main
$ sh ci/check.sh origin/main~3
checks: 11 file version(s) examined, 0 problem(s)
checks: 24 file version(s) examined, 0 problem(s)
tests: ok
[exit status: 0]
```
<!-- /snippet -->

Two design points. The hook and CI run the **same code** (`tools/checks.py`), so they cannot disagree about the rules. And the CI script checks two things: every file version the branch **adds** (`--range`), which catches a file that was committed and removed again within the branch and is therefore still in history, and the final snapshot (`--tree`). Both read blobs from Git, never the working tree, so they judge what is in history.

| Layer | Runs where | Can the author skip it? | Role |
|---|---|---|---|
| Editor and local hook | the author's clone | yes: not installed, `--no-verify`, another client | fast feedback |
| CI job as a **required** check | GitHub Actions | no, if a ruleset requires it and bypass is restricted | the control for the branch |
| Push protection and push rulesets | GitHub, at push time | only through a logged bypass | stops secrets and oversized files before they are stored ([push protection](https://docs.github.com/en/code-security/concepts/secret-security/push-protection)) |

> **GitHub, not Git.** A CI check catches a secret after it has been pushed: the commit is already on the server, and the credential must be rotated. Only a server-side control at push time (push protection, a push ruleset, or a `pre-receive` hook on a server you run) prevents the bytes from arriving. Use CI for policy, and push-time controls for secrets and size.

## 28.11 CI for ML projects: matrices, caches, GPU runners and LLM evaluations

**In one sentence.** The CI of an ML repository is ordinary until it needs a GPU, a multi-gigabyte model or a paid API key, and each of those three collides with a default of GitHub Actions.

**The ordinary part.** A Python version matrix, installs driven by the lock file, and a dependency cache. uv's guide pins `astral-sh/setup-uv` to a full commit SHA and installs with `uv sync --locked` ([uv with GitHub Actions](https://docs.astral.sh/uv/guides/integration/github/)). This course's [`workflows/04-python-tests.yml`](../workflows/04-python-tests.yml) is that job, with the action pins of 1 October 2026; Chapter 20A: GitHub Actions fundamentals explains every line. For `docqa`, one more step runs `sh ci/check.sh` with the base of the pull request, and the checkout needs `fetch-depth: 0` so that the range exists.

Three pressure points are specific to ML. All facts are GitHub's, from the report.

**GPU capacity.** GitHub-hosted GPU runners come in one shape, a 4-vCPU machine with a single T4. Larger runners, GPU included, are available only to organizations on Team and Enterprise Cloud plans and are always billed per minute, with no included minutes ([larger runners](https://docs.github.com/en/actions/reference/runners/larger-runners)). That is enough for a smoke test of a small model, not for training. Teams that need more run self-hosted GPU runners, which is a security decision before it is a capacity decision (below).

**Caches.** Caches are free up to 10 GB per repository, and anyone who can open a pull request can read them, so a cache is not a place for anything sensitive. They suit package caches and small test models, not multi-gigabyte checkpoints. Fetch large models by pinned reference from the model store inside the job, or bake them into a runner image.

**LLM evaluations.** An evaluation that calls a model provider needs an API key in CI. promptfoo's GitHub Action runs a before-and-after evaluation of edited prompts on pull requests, and DeepEval integrates with pytest and fails the build when a metric falls below a threshold; Inspect AI, Ragas and the LangSmith SDK are also maintained ([promptfoo](https://www.promptfoo.dev/docs/integrations/github-action/), [DeepEval](https://deepeval.com/docs/evaluation-unit-testing-in-ci-cd)). CML, once the usual way to post model metrics on pull requests, has had no release since October 2024; the report infers from repository activity that it is dormant, and no official statement says so ([CML releases](https://github.com/iterative/cml/releases)).

Such evaluations differ from unit tests in three ways the report names: they are non-deterministic, they cost money per run, and they need secrets. The first two shape how you use them:

| Property | Consequence for the workflow |
|---|---|
| Non-deterministic | compare against a threshold or a baseline with a tolerance, never for equality; record model version, prompt version and seed with the result (section 28.7) |
| Costs money per run | trigger on paths that matter (`prompts/**`, `configs/**`, `evals/**`), cap the data set for pull requests, run the full suite on a schedule or on `main` |
| Needs secrets | see below |

**The collision with the fork model.** Secrets are not passed to workflows triggered by `pull_request` from a fork ([Chapter 27: Open source and team workflows](ch27-open-source-team-workflows.md), section 27.2). So the evaluation job fails on exactly the contributions an open-source LLM project most wants to evaluate. The tempting repair is to switch the trigger to `pull_request_target`, which runs with the base repository's secrets, and then check out the contributor's code. That combination executes untrusted code with your API keys and your token. The report identifies it as the pattern behind several compromises, some of them in ML projects (PyTorch's self-hosted runners, Ultralytics, LiteLLM), and Chapter 21A: GitHub Actions security takes it apart.

```text
   pull_request from a fork            pull_request_target + checkout of the fork's code
  +---------------------------+       +------------------------------------------------+
  | contributor's code runs   |       | contributor's code runs                        |
  | no secrets, read-only     |       | WITH the base repository's secrets and token   |
  | token                     |       |                                                |
  | -> evaluation cannot call |       | -> evaluation works, and so does               |
  |    the model provider     |       |    "print the API key" in a changed test file  |
  +---------------------------+       +------------------------------------------------+
```

Defensible designs, from least to most machinery:

1. **Do not evaluate fork pull requests automatically.** Run cheap, secret-free checks on `pull_request` (lint, unit tests, `ci/check.sh`, evaluation against a local stub or recorded responses). A maintainer triggers the paid evaluation after reading the diff.
2. **Evaluate after merge.** Run the evaluation on `main` and alert or revert on regression.
3. **Separate data from code.** If the change is only to prompts or configuration, a trusted workflow can read those files as data and run the base repository's own evaluation code on them. This is safe only if nothing from the pull request is executed, which includes test files, `conftest.py`, package scripts and anything a prompt template can make the harness import.

**Self-hosted GPU runners.** They concentrate risk because they are expensive, long-lived and hold cached models and cloud credentials. The configuration the report calls defensible: private repositories or approval for all outside contributors, ephemeral runners that perform one job, runner groups scoped to named repositories, and OIDC instead of long-lived keys on the host. GitHub's own guidance is that self-hosted runners should almost never be used for public repositories.

**In production.** Give the evaluation job its own provider key with a spend cap, separate from production's. When that key leaks through a log or a compromised action, the damage is a bill with a ceiling, not production traffic.

## 28.12 A professional AI project repository

**In one sentence.** A good layout makes the rules of this chapter the path of least resistance: there is an obvious place for everything that belongs in Git and an ignored place for everything that does not.

> **Assembled, not authoritative.** No single authoritative layout exists. Two reference points are well documented: Cookiecutter Data Science v2 generates `data/` split into raw, interim, processed and external, a `notebooks/` directory with a naming convention, `models/`, `reports/` and an importable source package, and its ignore file ignores `/data/` ([CCDS](https://github.com/drivendataorg/cookiecutter-data-science/blob/master/README.md)); and the Python Packaging Authority describes the trade-off between the flat and `src/` layouts without a blanket recommendation ([PyPA](https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/)). The tree below is this course's assembly for an LLM application, built from those and from the mechanisms above.

**See it.** `docqa`, as Lab 33.1 builds it from an empty folder. Everything Git tracks:

<!-- snippet: ch28/project-skeleton/01-tracked -->
```text
$ git ls-files
.dockerignore
.gitattributes
.gitignore
Dockerfile
README.md
ci/check.sh
configs/eval.json
data/README.md
data/raw/tickets.csv.ref
evals/run_eval.py
hooks/pre-commit
models/README.md
models/embedder.bin.ref
notebooks/01-error-analysis.ipynb
prompts/answer.v1.txt
pyproject.toml
requirements.lock
src/docqa/__init__.py
src/docqa/classify.py
tests/test_classify.py
tools/checks.py
tools/dataref.py
tools/nbstrip.py
tools/runinfo.py
```
<!-- /snippet -->

And what is on disk and deliberately not tracked:

<!-- snippet: ch28/project-skeleton/03-ignored -->
```text
# On disk but deliberately not in Git:
$ git status --short --ignored
!! data/raw/tickets.csv
!! models/embedder.bin
!! runs/
$ git check-ignore -v data/raw/tickets.csv models/embedder.bin runs/baseline/run.json
.gitignore:17:/data/**	data/raw/tickets.csv
.gitignore:23:/models/**	models/embedder.bin
.gitignore:34:/runs/	runs/baseline/run.json
```
<!-- /snippet -->

**The tree, with every component explained.**

```text
docqa/
|-- .gitignore              what must never be added by accident (section 28.9)
|-- .gitattributes          line endings, the notebook filter, pointers merged as binary
|-- README.md               what the project is, and the commands a new clone must run once
|-- pyproject.toml          package metadata and dependency ranges
|-- requirements.lock       exact versions (uv.lock in a real project); committed (section 28.8)
|-- Dockerfile              the serving image; base image passed in pinned by digest
|-- .dockerignore           keeps .git, .env, data and runs out of the build context
|-- src/docqa/              the importable package: all logic that deserves tests lives here
|-- tests/                  unit tests; fast, no network, no secrets
|-- configs/                evaluation and model settings; reviewed like code
|-- prompts/                prompt templates, one file per version; reviewed like code
|-- evals/                  the evaluation entry point; writes a run record (section 28.7)
|-- notebooks/              exploration; committed without outputs (section 28.4)
|-- data/                   README and *.ref pointers only; the data itself is ignored
|-- models/                 README and *.ref pointers only; weights are ignored
|-- tools/                  repository tooling: filter, checks, pointer tool, run recorder
|-- hooks/                  shared Git hooks, enabled per clone with core.hooksPath
|-- ci/                     the one script CI runs, runnable locally
`-- runs/                   local run outputs; ignored (a tracker holds the durable copy)
```

Files the lab does not create and a real repository on GitHub should have: `.github/workflows/` for CI (section 28.11), `.github/CODEOWNERS` so that changes to workflows, lock files, prompts and the `Dockerfile` get a named reviewer ([Chapter 19: CODEOWNERS](ch19-codeowners.md)), `.github/dependabot.yml` (section 28.13), `SECURITY.md`, a licence, and `.env.example` listing the variable names a developer must set, with no values.

**The order of the history matters as much as the tree.**

<!-- snippet: ch28/project-skeleton/02-history -->
```text
$ git log --oneline --decorate
aa18ad2 (HEAD -> main, tag: v0.1.0) Add serving image definition and model pointer
8a681ec Add evaluation config, prompt and run recorder
1117838 Version the ticket data set by reference
6be6418 Add notebook filter and the error-analysis notebook
ef4b558 Add repository checks, shared hook and CI entry point
8484ac0 Add package skeleton, lock file and tests
426268a Add ignore rules and attributes before any content
```
<!-- /snippet -->

Read it from the bottom. The ignore rules and attributes are the **first** commit, before any content exists that they should have caught. The checks and the hook arrive before the first notebook. The notebook filter arrives in the same commit as the first notebook. The pointer tool arrives with the first data. Each safeguard precedes the thing it guards, so there is no window in which a mistake can enter history. A repository that adds `.gitignore` in commit forty has thirty-nine commits to audit.

**What a clone must do.**

<!-- snippet: ch28/project-skeleton/07-clone-setup -->
```text
# What a clone has, and what it does not have:
$ git clone -q . ../docqa-asha && cd ../docqa-asha
$ git config get filter.nbstrip.clean
[exit status: 1]
$ git config get core.hooksPath
[exit status: 1]
$ python3 tools/dataref.py verify
missing  data/raw/tickets.csv  (pointer sha256:2226b23c455b)
missing  models/embedder.bin  (pointer sha256:7daca2095d04)
[exit status: 1]
```
<!-- /snippet -->

No filter, no hook path, no data. This is why the README of `docqa` opens with the five commands a new clone runs once, and why CI repeats the checks. A `make setup` target or a bootstrap script that runs those commands is worth having; it is a convenience and still not a control.

**Monorepo or one repository per model?** The report found no ML-specific primary study, so this is a trade-off, not a finding. One repository gives atomic changes across training code, serving code and shared libraries and needs CI that runs only what changed ([Chapter 24: Monorepos](ch24-monorepos.md)). Separate repositories give each team its own release rhythm and access control, and turn every shared library into a versioned dependency.

## 28.13 Model-serving repositories, Docker, and the Java and backend side

**Serving.** The report found no authoritative layout for model-serving repositories; what it found are three sourced building blocks, and the `Dockerfile` of `docqa` is shaped by them.

- **Secrets never enter the image through build arguments or environment variables.** Docker's documentation says both persist in the final image, and provides secret mounts for the purpose ([build secrets](https://docs.docker.com/build/building/secrets/)). From that documentation, not run here:

  ```bash
  docker build --secret id=aws,src=$HOME/.aws/credentials .
  # in the Dockerfile:  RUN --mount=type=secret,id=aws  <command that needs the credentials>
  ```

- **Weights are fetched by pinned reference, never committed.** At build or start time the image downloads the revision or checksum recorded in the repository (section 28.6).
- **The base image is pinned by digest** (section 28.8), and `.dockerignore` keeps `.git`, `.env`, data and run outputs out of the build context, which is the Docker analogue of `.gitignore` and matters for the same reason: a `COPY . .` with a credential file in the context bakes it into a layer.

The link back to Git is the image label. Record the commit in the image (the OCI annotation `org.opencontainers.image.revision` exists for it) and tag images by commit ID or release tag, so that "which code is serving" has one answer.

> **Unverified.** The annotation name `org.opencontainers.image.revision` is given from the author's knowledge of the OCI image specification; it is not in the report or its notes. Confirm it in the specification before you depend on it.

**Java and backend notes.** An ML platform is rarely Python alone: the service that calls the model is often Java. Three facts from the report matter.

- **Ignore rules.** GitHub's templates ignore `target/`, `build/`, `.gradle` and `*.class`. They treat the two build wrappers differently: the Maven wrapper JAR is ignored, while the Gradle template explicitly un-ignores `gradle-wrapper.jar`, which Gradle's documentation says is expected to be committed ([Maven template](https://github.com/github/gitignore/blob/main/Maven.gitignore), [Gradle template](https://github.com/github/gitignore/blob/main/Gradle.gitignore), [Gradle Wrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html)).
- **The committed JAR is a review blind spot.** It is the one place in a typical Java repository where a pull request can change executable code that a reviewer cannot read in a diff. That is why `gradle/actions/wrapper-validation` exists, and why `setup-gradle` validates wrappers automatically since its v4 ([wrapper validation](https://github.com/gradle/actions/blob/main/docs/wrapper-validation.md)). The parallel in this chapter: weights are also unreadable in a diff, which is one more reason they travel as checksums.
- **Dependabot needs one entry per ecosystem.** A polyglot repository lists `pip` or `uv`, `maven` or `gradle`, `github-actions`, and `docker` separately; `uv` has had version updates since 13 March 2025 and security updates since 16 December 2025, and `docker` and `pre-commit` receive version updates only ([supported ecosystems](https://docs.github.com/en/code-security/dependabot/ecosystems-supported-by-dependabot/supported-ecosystems-and-repositories)).

> **Unverified.** Maven's own documentation on distributing the wrapper was not fetched for the report; the statement above rests on GitHub's template.

## 28.14 Secrets in AI repositories

**In one sentence.** AI repositories leak the same way as others and through three extra paths: notebook outputs, agent and tool configuration files, and evaluation logs.

**The scale, from the report.** GitGuardian counted 28,649,024 new secrets on public GitHub in 2025, of which 1,275,105 were tied to AI services, up 81%; 24,008 unique secrets sat in MCP configuration files; and commits co-authored by Claude Code leaked secrets at roughly twice the baseline rate ([State of Secrets Sprawl 2026](https://www.gitguardian.com/state-of-secrets-sprawl-report-2026)). These are one vendor's measurements of public repositories.

**Why an LLM key is worse than a bill.** The report's example is an xAI key, hardcoded and pushed in 2025, that gave access to at least 60 private and fine-tuned models and was still valid two months after the first alert ([Krebs on Security](https://krebsonsecurity.com/2025/05/xai-dev-leaks-api-key-for-private-spacex-tesla-llms/)). What a provider key exposes depends on the provider and the key's scope; assume it is more than usage charges.

| Leak path specific to AI work | Mechanism | Control |
|---|---|---|
| Notebook outputs | a cell prints a key or a data frame; the file stores it (section 28.3) | strip outputs; verify in CI |
| `.env` files | created for local runs, added by `git add .` | ignore rule; `.env.example` without values; push protection |
| Agent and tool configuration (MCP server files, editor agent settings) | a token pasted into a JSON or YAML file that looks like configuration, not like a credential | keep tokens in the environment or a secret manager; scan these paths |
| Evaluation logs and traces | request headers or full prompts logged and committed as "results" | keep run outputs out of Git (`runs/` is ignored); redact at the source |
| Prompts and fixtures | real customer text pasted into a test case | review `prompts/` and `tests/` like code; synthetic fixtures |
| CI | a key printed by a debugging step, or exfiltrated by untrusted code (section 28.11) | least privilege, spend caps, no secrets on fork pull requests |

**The rule that does not change.** A commit that deletes a secret adds a snapshot and leaves the old one in history, in every clone and fork. The order is: revoke or rotate first, then find out what the key could reach, then clean up. Chapter 21B: Repository security has the full procedure. `git rm --cached .env` followed by a commit is not a response to a leak.

## 28.15 AI coding agents as participants in the workflow

**In one sentence.** An agent that writes commits is a contributor with a different Git client, unusual speed and no memory of your conventions, so the controls that matter are the ones that do not depend on the contributor.

**What the report establishes.** By October 2026 agents are first-class actors on GitHub: Copilot can review pull requests and, in preview, approve them, and the Copilot cloud agent opens pull requests and signs its commits. DORA's 2025 research describes AI as an amplifier of an organization's existing strengths and weaknesses, lists version control and working in small batches among the capabilities that matter, and recommends small, frequent commits for AI-generated code ([DORA 2025 report](https://dora.dev/research/2025/dora-report/), [DORA: version control](https://dora.dev/capabilities/version-control/)).

**What follows for the repository,** as the report's inference:

| Property of an agent | Consequence | Control |
|---|---|---|
| It may use its own Git client or the API | local hooks do not run | every hook that matters is also a required check (section 28.10) |
| It produces large changes quickly | review becomes the bottleneck, or stops being real | small pull requests; a human approval that an automated approval cannot replace, enforced by a ruleset |
| It reads whatever is in the repository and in the task | text in an issue, a pull request title or a file can steer it (prompt injection) | do not run agents automatically on untrusted contributions; no write token unless required |
| It holds credentials while it works | whatever it can read, an attacker who steers it can read | a dedicated low-privilege, spend-capped key; narrowly scoped tokens |
| It does not know your conventions | inconsistent branch names, messages, generated files committed | conventions in a committed instruction file, and checks that enforce them anyway |

Two incidents from the report show the third and fourth rows are not hypothetical: an automated account ran a campaign in February and March 2026 that combined `pull_request_target` abuse, injection through branch names and filenames, and prompt injection against an AI reviewer ([StepSecurity](https://www.stepsecurity.io/blog/hackerbot-claw-github-actions-exploitation)); and researchers reported in April 2026 that AI coding agents run as GitHub Actions could be steered by text in pull-request titles, issue bodies or comments into revealing CI secrets ([Techzine](https://www.techzine.eu/news/security/140524/ai-agents-on-github-leak-api-keys-via-prompt-injection/)).

> **Unverified.** The April 2026 research was verified for the report only through that one secondary article.

**Attribution.** Decide how agent-written commits are marked: a `Co-authored-by` trailer, a dedicated bot account, or a signature. Then "which changes did an agent write" is a `git log` query ([Chapter 27](ch27-open-source-team-workflows.md), section 27.18), and when a model version turns out to have introduced a class of bug you can find its commits.

**The practical conclusion.** Nothing in this chapter becomes less important when an agent writes the commits, and most of it becomes more important, because the volume goes up and the author cannot be asked what it meant.

## 28.16 What can go wrong

| Symptom | Diagnosis | Fix | Prevention |
|---|---|---|---|
| A notebook nobody edited shows as modified on every run | outputs and counters are in the blob: `git cat-file -p HEAD:<nb> \| grep -c output_type` | configure the filter; `git add --renormalize .`; commit | filter plus `--verify` as a required check |
| Outputs in history although "we use nbstripout" | the committing clone had no filter: `git config get filter.<name>.clean` exits 1 there | strip and commit; if a secret was printed, rotate it | setup script; CI check; `required = true` |
| `git add` fails with "clean filter ... failed" | the filter is required and its program is missing or broken | install the tool or fix the path in the clone's configuration | document setup in the README; do not unset `required` to make the error go away |
| Checking out a run's commit gives another metric | the run was made from a dirty tree, or with other data | apply the saved patch; restore the data version the record names | refuse dirty runs; record data checksum and diff |
| The metric changed and no commit did | the data file was edited in place: `dataref.py verify` reports "differs" | record the new version, or restore the old one | the evaluation refuses data that does not match its pointer |
| A pointer cannot be resolved ("NOT IN STORE") | the object was deleted from the store, or never pushed | restore from backup; otherwise the version is lost | retention rules; push data before pushing the pointer |
| The clone is slow and `.git` is large | a big blob in history: the `rev-list --objects` pipeline of section 28.9 | history rewrite, coordinated; or accept and use partial clone ([Chapter 26: Performance](ch26-performance.md)) | size checks in CI; a push ruleset on file size |
| A large or secret file reached `main` "despite the hooks" | the clone had no hook, or `--no-verify` | remove; rotate if secret | the same checks as a required CI job; push protection |
| The evaluation job fails on every fork pull request | secrets are withheld from fork runs | secret-free checks on `pull_request`; a maintainer-triggered evaluation | design the split up front (section 28.11) |
| The package version in CI is `0.0.0` or the job fails in `git describe` | shallow checkout without tags | `fetch-depth: 0` | set it in jobs that derive versions |

## 28.17 When not to use it, and dangerous edge cases

- **Do not strip outputs when the outputs are the deliverable.** A report notebook whose charts are the result needs the outputs; commit them on purpose and review them with a tool that can.
- **A clean filter makes `git status` lie by design.** The working file and the blob differ and Git reports no change. Anyone who copies the working file elsewhere (an email, a bucket, a Docker build context) copies the outputs too. Keep `notebooks/` out of the build context.
- **Pointers are not backups.** Versioning by reference moves the durability requirement to the store. A bucket with a lifecycle rule that expires old objects silently destroys old versions.
- **Do not use Git LFS for data that must be deletable.** The report notes that LFS objects are hard to remove from the server; personal data with a deletion obligation belongs in a store with real deletion.
- **`dataref.py checkout`, like `dvc checkout`, overwrites the working data file.** Unrecorded edits to the data are lost, with no reflog to recover them. Run `verify` first.
- **A dirty-tree record with a patch still omits untracked files.** A new module that was never added is not in `git diff HEAD`.
- **`git add -f` defeats every ignore rule,** and `git add .` after `git rm --cached` of a file that is no longer ignored re-adds it.
- **Renormalizing a large repository touches many files in one commit.** Do it in a commit of its own, announced, so that it does not hide in a feature diff and so that `git blame --ignore-rev` can skip it ([Chapter 14A: History investigation](ch14a-history-investigation.md)).
- **This chapter's scripts are teaching instruments.** `nbstrip.py`, `dataref.py` and `checks.py` show mechanisms. In a real project use the maintained tools, which handle the cases forty lines cannot.

## 28.18 Command safety

| Command | Label | What it changes | Preview | Recovery |
|---|---|---|---|---|
| `git check-ignore -v`, `git check-attr`, `git status --ignored`, `git cat-file -p <rev>:<path>`, `git describe` | 🟢 SAFE | nothing | not needed | not needed |
| `git config set filter.<name>.clean ...`, `git config set core.hooksPath hooks` | 🟡 CAUTION | how later `git add` and `git commit` behave in this clone | `git config list --local` | `git config unset <key>` |
| `git add <notebook>` with a clean filter | 🟢 SAFE | stages the cleaned form | `git diff` (compares cleaned forms) | `git restore --staged <path>` |
| `git add --renormalize .` | 🟡 CAUTION | re-cleans and restages every tracked file | `git status` afterwards, before committing | `git restore --staged .` |
| `git restore <notebook>`, `git switch` across a notebook change | 🔴 DANGEROUS for local outputs | rewrites the file from the stripped blob | `git status`; copy the file first | none: outputs were never in Git; rerun the notebook |
| `git rm --cached <path>` | 🟡 CAUTION | removes the path from the index; the next commit deletes it for everyone who pulls | `git status` | `git restore --staged <path>` before committing |
| `git commit --no-verify` | 🟡 CAUTION | commits without the pre-commit and commit-msg hooks | run the hook by hand: `hooks/pre-commit` | `git commit --amend` after fixing; CI is the backstop |
| `git worktree add --detach <dir> <commit>` | 🟢 SAFE | a new directory and an entry under `.git/worktrees/` | `git worktree list` | `git worktree remove <dir>` |
| `git apply <patch>` | 🟡 CAUTION | working tree files | `git apply --check <patch>`; `git apply --stat <patch>` | `git restore <paths>` |
| `python3 tools/dataref.py checkout` (and `dvc checkout`) | 🔴 DANGEROUS for unrecorded data edits | overwrites data files with the versions the pointers name | `python3 tools/dataref.py verify` | none for unrecorded edits; record them first with `add` |

For the two 🔴 rows: what they change and destroy is in the table; they are appropriate whenever the working copy holds nothing that exists only there, which is the normal case after `verify` reports "ok" or after outputs have been exported.

## 28.19 Version notes

> **Version note.** Older behavior: `git config filter.x.clean ...` and `git config --unset`. Current behavior: `git config set`, `git config get`, `git config unset`, `git config list`. Since: Git 2.46. Recommended: the subcommands; the old forms still work.

> **Version note.** Older behavior: Git LFS data packs on GitHub. Current behavior: metered billing ([Chapter 22: Git LFS](ch22-git-lfs.md), section 22.11). Recommended: check the billing page before putting model files in LFS.

> **Version note.** Older behavior: Hugging Face Hub repositories stored large files in Git LFS storage. Current behavior: Xet storage, with the LFS pointer format kept for compatibility. Since: migration reported complete by October 2025 (flagged above as not independently verified). Recommended: pin downloads by full commit hash either way.

> **Version note.** Older behavior: DVC maintained by Iterative; lakeFS under Apache 2.0. Current behavior: DVC stewarded by lakeFS since 18 November 2025 and still Apache-2.0; lakeFS under the Business Source License from v1.87.0 (22 September 2026). Recommended: state the version when you describe either licence.

> **Version note.** Older behavior: CML as the usual way to post model metrics on pull requests. Current behavior: no release since October 2024. Recommended: post results from your evaluation tool or a small script; do not build new pipelines on it without checking its status.

Tool versions quoted in this chapter (nbstripout 0.9.1, nbdime 4.0.4, jupytext 1.19.5, DVC 3.67.1, pre-commit 4.6.2, prek v0.5.4, uv 0.12.21, MLflow 3.16.1, W&B SDK 0.30.0, setuptools-scm 10.3.4, hatch-vcs 0.5.0, Git LFS client 3.8.0) are those the report recorded on 1 October 2026. None of the tools was run for this chapter.

## 28.20 Practice

- [Lab 33.1](../lab-manual/m33-ai-ml-workflows.md): build `docqa` from an empty folder, in the order that keeps mistakes out of history; then commit a notebook from a clone without the filter, catch it, and repair it.
- [Lab 33.2](../lab-manual/m33-ai-ml-workflows.md): version a data set by reference, move between versions, restore it in a clone, and catch an unrecorded edit.
- [Lab 33.3](../lab-manual/m33-ai-ml-workflows.md): reproduce a past result from its recorded identifiers, including one made from a dirty tree.
- Lab 14.4 in the Module 14 labs is the smaller filter exercise this chapter builds on; the Module 22 labs cover Git LFS.
- Run the demos: `labs/run ch28/notebook-filter`, `labs/run ch28/run-record`, `labs/run ch28/hooks-vs-ci`.

## 28.21 Interview questions

1. A run in the tracker names a commit. You check it out and get a different metric. List every cause you can think of, in the order you would test them, and the evidence for each.
2. Why does cloning a repository not install its clean filters and hooks? What would be possible for an attacker if it did?
3. Explain what a clean filter marked `required` does differently from one that is not, and why that matters for a filter that strips notebook outputs.
4. Your team "uses nbstripout", and a notebook with outputs is on `main`. How did it get there, and what do you change?
5. Compare Git LFS, DVC and a pointer file you maintain yourself. What is identical in all three, and what differs?
6. `.gitignore` lists `*.ckpt`, and `git status` shows `model.ckpt` as modified. Explain, fix it, and say what your fix did not fix.
7. Which files in an ML repository are generated and must be committed anyway, and what is the test that separates them from generated files that must not be?
8. An open-source LLM project wants evaluations on pull requests from forks. Describe the collision, the dangerous workaround, and two designs you would defend.
9. What does a local pre-commit hook guarantee? Name three ways a commit reaches the server without passing it, and the control for each.
10. An agent opens forty pull requests a day in your repository. Which of your existing controls still work, which do not, and what do you add?
11. A colleague deleted a leaked provider key in a follow-up commit and considers the incident closed. What is still true, and what is the first action?
12. Why is `merge=binary` a sensible attribute for a pointer file?

## 28.22 Sources

**Primary sources**

- Git 2.55 manual pages: `git help attributes` (filters, `text`, `merge`), `git help ignore`, `git help check-ignore`, `git help describe`, `git help status` (porcelain format), `git help worktree`, `git help apply`.
- Notebooks: [nbformat](https://nbformat.readthedocs.io/en/latest/format_description.html), [nbstripout](https://github.com/kynan/nbstripout/blob/main/README.md), [nbdime](https://nbdime.readthedocs.io/en/latest/) and its [Git integration](https://nbdime.readthedocs.io/en/latest/vcs.html), [jupytext](https://github.com/jupytext/jupytext/blob/main/README.md), [ReviewNB](https://www.reviewnb.com/), GitHub's [rich notebook diff preview](https://github.blog/changelog/2023-03-01-feature-preview-rich-jupyter-notebook-diffs/).
- Data and models: [About large files on GitHub](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github), [About Git LFS](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage), [DVC: get started](https://doc.dvc.org/start), [DVC joins lakeFS](https://dvc.org/blog/dvc-joins-lakefs-your-questions-answered/), [lakeFS licence change](https://lakefs.io/blog/lakefs-business-source-license/), [Hugging Face download guide](https://huggingface.co/docs/huggingface_hub/guides/download), [MLflow model registry](https://mlflow.org/docs/latest/ml/model-registry/).
- Reproducibility: [MLflow system tags](https://mlflow.org/docs/latest/ml/tracking/tracking-api/), [W&B code saving](https://docs.coreweave.com/models/app/features/panels/code), [Hydra output directory](https://hydra.cc/docs/tutorials/basic/running_your_app/working_directory/), [uv project layout](https://docs.astral.sh/uv/concepts/projects/layout/) and [locking](https://docs.astral.sh/uv/concepts/projects/sync/), [Docker build best practices](https://docs.docker.com/build/building/best-practices/), [git-describe](https://git-scm.com/docs/git-describe).
- Hooks and CI: [pre-commit](https://pre-commit.com/), [pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks/blob/main/README.md), [ruff-pre-commit](https://github.com/astral-sh/ruff-pre-commit/blob/main/README.md), [uv with GitHub Actions](https://docs.astral.sh/uv/guides/integration/github/), [larger runners](https://docs.github.com/en/actions/reference/runners/larger-runners), [push protection](https://docs.github.com/en/code-security/concepts/secret-security/push-protection), [promptfoo GitHub Action](https://www.promptfoo.dev/docs/integrations/github-action/), [DeepEval in CI](https://deepeval.com/docs/evaluation-unit-testing-in-ci-cd).
- Structure, Docker and Java: [Cookiecutter Data Science](https://github.com/drivendataorg/cookiecutter-data-science/blob/master/README.md), [PyPA on src and flat layouts](https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/), [Docker build secrets](https://docs.docker.com/build/building/secrets/), [GitHub's Python ignore template](https://github.com/github/gitignore/blob/main/Python.gitignore), [Gradle Wrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html), [Dependabot ecosystems](https://docs.github.com/en/code-security/dependabot/ecosystems-supported-by-dependabot/supported-ecosystems-and-repositories).

**Secondary sources**

- The Phase 0 report of this course, sections 14 and 15, and its notes on AI/ML workflows and security. Every version, date, licence and status in this chapter comes from there; its flags are carried as "Unverified" callouts.
- GitGuardian, [How to handle secrets in Jupyter notebooks](https://blog.gitguardian.com/how-to-handle-secrets-in-jupyter-notebooks/) and [State of Secrets Sprawl 2026](https://www.gitguardian.com/state-of-secrets-sprawl-report-2026): one vendor's measurements.
- DORA, [2025 report](https://dora.dev/research/2025/dora-report/) and [version control capability](https://dora.dev/capabilities/version-control/).
- StepSecurity and Techzine on agents in workflows, linked in section 28.15.

**Videos** (from the report's tables, with its caveats)

- [MLOps: Day 4 - Data Versioning using DVC](https://www.youtube.com/watch?v=PPrPuxqWc7E), Vikash Das, in Hindi, 7 August 2024, 1 h 25 min: why Git alone does not suit data, DVC beside Git, an S3 remote, `dvc push` and `dvc pull`. Caveats: DVC CLI versions were not checked; no pipelines or CI.
- [How to build a ML project using MLOps](https://www.youtube.com/watch?v=eCjuoqUy8Is), CampusX, in Hindi, 25 November 2024, 1 h 21 min. Use it as a concept map only: the report notes no workflow YAML, no `dvc push` or `dvc pull`, and no remote storage.

**Further reading**

- [Chapter 14C](ch14c-stash-rerere-attributes-hooks.md) for filters, drivers and hooks in full; [Chapter 22](ch22-git-lfs.md) for Git LFS; [Chapter 25: Worktrees](ch25-worktrees.md) for the worktree used in Lab 33.3.
- [Chapter 27: Open source and team workflows](ch27-open-source-team-workflows.md) for branching, release tags and the fork model that section 28.11 collides with.
