# V176: Data and model versioning by reference, and reproducibility: the commit alone does not identify what ran

- **Part.** 8, Professional practice
- **Module.** 33
- **Planned minutes.** 26
- **Prerequisites.** V097, V175
- **Textbook sections.** [Chapter 28](../../textbook/ch28-ai-ml-workflows.md), sections 28.6 to 28.8
- **Demo scripts.** `labs/ch28/data-pointer.sh`, `labs/ch28/run-record.sh`, `labs/ch28/lab-33-3-reproduce-result.sh` (snippets `01-today` to `04-rerun`)

## HOOK

**[ON SCREEN]** "The dashboard says accuracy 0.90 for the run we showed the board. Check out the commit it names and show me 0.90."

You check out the commit. You run the evaluation. You get 0.80.

The commit is intact. Nothing was rewritten. The tracker didn't lie either: the run really was started at that commit. But the run was made from a working tree with an uncommitted change, and the tracker recorded only the commit. Two different code states shared one commit ID, and one of them is gone.

By the end of this video you can say exactly what a run record has to contain so that this can't happen, and you'll see a past result reproduced from its recorded identifiers. Remember the two numbers, 0.90 and 0.80. You'll watch one commit carry two results.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Three words first. A commit is one saved snapshot of the project. The working tree is the folder of files you edit and run. And a run is one execution of a training or an evaluation, whose result a tracker logs.

Video 175 dealt with the left column of the chapter's table: what is in Git. Today is the right column, and the arrow between them. Data and weights aren't in Git, and Git still has to say which data and which weights a commit used.

Two halves. First, versioning by reference: a pointer in Git, bytes elsewhere. You know one instance from video 97, Git LFS. Here you see the bare pattern, and then the real tools as variations of it. Second, reproducibility: the list of things that identify a run, of which the commit ID is only one.

As in video 175, the tools of the field, DVC, MLflow and the others, aren't installed in the lab. The pointer mechanism and the run recorder you'll see are stand-ins written for the lab with the Python standard library. Commands of the real tools are shown from their documentation, without output.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Version a dataset by committing a pointer and keeping the bytes elsewhere.
2. Say what Git LFS, DVC and a hand-made pointer have in common and where they differ.
3. List what a run record must contain besides the commit ID.
4. Detect a dirty or untracked state at run time and record it.
5. Reproduce a past result from its recorded identifiers.

## CONCEPT

**[ANIMATION]** hash: differs=byte lines=data/raw/tickets.csv,432_bytes alt=606_bytes ids=2226b23c455b,4efbc43184d3 left=the_data_set right=four_tickets_later fn=SHA-256 title=A_checksum_names_one_version_of_the_data same=The_same_bytes_always_give_the_same_checksum diff=Four_more_tickets:_another_checksum

**Versioning by reference.** You version a large file by committing a small file that names it by checksum, and by keeping the bytes in a store that is addressed by that checksum. A checksum is a fingerprint computed from every byte of a file. Identical bytes always give the same one, and one changed byte gives a different one.

Every tool in this area is a variation on one pattern, which you met as Git LFS:

1. Compute a cryptographic hash of the file.
2. Store the file outside Git under that hash: content-addressed storage.
3. Commit a small pointer that records the hash and the size.
4. Tell Git to ignore the real file, or let a filter swap pointer and file.

Git then versions the pointer. `git log`, `git diff`, branches, tags and pull requests all work on it, and "which data did this commit use" has an exact answer.

**The central weakness.** The pointer and the file can disagree, and Git won't tell you. Git doesn't watch an ignored file. You'll see that in the terminal.

**The real tools.** The table is from the course's research report, with its dates and flags.

**[ON SCREEN]** The table of section 28.6.

| Tool | Status on 1 October 2026 | Mechanism | When it fits, and caveats |
|---|---|---|---|
| Git LFS | client 3.8.0; GitHub caps a file at 2 to 5 GB by plan; metered billing | a three-line pointer in Git, swapped by a required filter; objects in LFS storage | a modest number of mid-sized, rarely changing binaries. Wrong when files exceed the cap, change often, must be deletable, or when CI and contributors lack the client |
| DVC | 3.67.1 (31 March 2026); Apache-2.0; stewardship moved to lakeFS on 18 November 2025 | a `.dvc` metafile per tracked path; the data path is added to `.gitignore`; data moves with `dvc push` and `dvc pull` | Git-based versioning for small to medium projects. Maintained; no release in the six months after March 2026, and its roadmap is unstated |
| lakeFS | v1.88.0; **Business Source License from v1.87.0** (22 September 2026); earlier releases remain Apache 2.0 | Git-like branches over object storage | platform-scale data. Do not call it open source without the version caveat |
| git-annex | 10.20260901 | manages large files with Git without storing their contents in Git | a niche alternative |
| Hugging Face Hub | all repositories migrated from Git LFS storage to Xet by October 2025; the LFS pointer format is kept for compatibility | Git repositories whose large files are routed through `.gitattributes`; byte-level deduplication | pin what you download |
| Model registries | MLflow 3.16.1; W&B SDK 0.30.0 | versioned models with lineage to the producing run; mutable aliases | record the Git commit beside the model version |

**[ON SCREEN]** Unverified.

Two flags are carried from the report. The Hugging Face "all repositories migrated" claim dates from October 2025 and wasn't independently verified for 2026. And no statement of DVC's roadmap was found.

What they have in common: a hash, a store, a pointer in Git. Where they differ: how the second step happens when you move between commits. With the hand-made pointer and with DVC, going back is two steps: Git moves the pointer, the tool moves the bytes. Git LFS hides the second step inside a smudge filter, which is more convenient, and is why a clone without the LFS client silently gets pointers.

**[ON SCREEN]** DVC from its documentation; not run here.

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

The DVC guide says of itself that DVC "is technically not a version control system": it manipulates metafiles that Git versions.

**Pinning a model from a hub.** A model ID such as `org/name` names whatever the publisher's default branch points at today. The Hugging Face download guide documents a `revision` parameter that accepts a branch, a tag or a commit hash, and says a commit hash must be the full-length hash, not a seven-character abbreviation. A branch or tag in `revision` is a moving reference, exactly as a Git branch is. Commit the hash you evaluated. That line of configuration is the model's pointer file. Registry aliases such as `champion` are mutable by design, which is what makes promotion a one-step operation and what makes an alias useless as a record. Deploy by alias if you like. Log the resolved version number and the Git commit of the training code beside it.

**[ANIMATION]** trees: file=configs/eval.json steps=setup,edit commits=aa18ad2 versions=as_committed,one_more_keyword title=What_ran,_and_what_the_commit_says say_edit=Python_runs_the_files_on_disk._The_tracker_wrote_down_HEAD.

**[ANIMATION]** step: setup

**Reproducibility.** A result is identified by the commit, the state of the working tree relative to that commit, the data and model versions, the resolved configuration and the environment. Record all of them or you have recorded a guess.

**[ANIMATION]** step: edit

The tools capture less than people assume. Picture one tracked file, edited and not committed: the working tree has the new version, and the last commit does not. A tree in that state is called dirty. The textbook gives three tools, from the report.

MLflow: the classic run context sets the commit, the branch and the repository URL when the entry point is inside a Git repository, and doesn't inspect or record uncommitted changes. A newer, opt-in function marked experimental records the dirty state and the diff.

**[ANIMATION]** end

Weights and Biases: it generates a patch of uncommitted changes when code is logged, but code saving is disabled by default for all teams.

Hydra: it writes the resolved configuration and the command-line overrides into a `.hydra` directory for every run.

**[ON SCREEN]** Unverified.

Four caveats are attached to these statements, and they stay attached. The report flags a conflict about MLflow's branch tag: the documentation table says it is set for MLflow Projects only, the source code sets it for any run inside a repository, and the source is the more reliable description. The opt-in function is described from source code, not from a documentation page. W&B's exact default for commit capture when code saving is off wasn't tested, and a bug report about missing patch files exists, so verify capture instead of assuming it. Hydra's behavior was read from the development documentation, not re-verified against release 1.3.7.

The consequence, in the report's words: with classic tracking, two different code states can share one commit ID.

**Lock files, digests, resolved configuration.** Three rules from section 28.8.

Lock files are committed. A lock file lists the exact version of every dependency. A dependency range is resolved to exact versions at install time, so two installs a month apart differ. uv, version 0.12.21, documents `uv.lock` as a cross-platform lock file that should be checked into version control, and `--locked` as the option that raises an error instead of updating a lock file that is out of date. A lock file is generated, and it's still committed, because it's an input to every later build. The test for "generated files do not belong in Git" is whether the file can be regenerated identically from what is in Git. A lock file cannot, since the package index changes.

Container images are pinned by digest. An image tag is a mutable reference, like a branch. The parallel with Git is exact: tag is to digest as branch is to commit ID.

Configuration is recorded resolved. A configuration built from defaults, files, environment variables and command-line overrides exists in its final form only at run time.

And one consequence for CI: versions derived from tags need the tags. `git describe` names a commit by the most recent reachable annotated tag, and packaging plugins derive the package version from it. The default `actions/checkout` fetches one commit and no tags, so the derived version fails or falls back. Set `fetch-depth: 0` in the jobs that need it.

**[ON SCREEN]** The table that closes section 28.8.

| Identifier | Mutable reference (do not record) | Immutable identifier (record) |
|---|---|---|
| Code | branch name, `HEAD` | full commit ID, plus dirty flag and diff hash |
| Dependencies | version ranges in `pyproject.toml` | the committed lock file, or its hash |
| Environment | image tag | image digest |
| Data | file path, "latest" | checksum from the pointer file |
| Model | model name, registry alias, hub branch | registry version number; hub commit hash |
| Configuration | defaults plus overrides | the resolved configuration |

Quick quiz, with the table on screen. Which of these may go into a run record as the identity of the model? A, the model name. B, the registry alias `champion`. C, the hub commit hash. Your answer?

**[PAUSE]**

C. A name and an alias can point at something else tomorrow. The commit hash is in the right-hand column: it can't move.

## MENTAL MODEL

Two pictures, one for each half. For the pointer, the textbook's analogy is a coat-check ticket. The ticket is small and travels with you. The coat stays in the cloakroom. The analogy breaks in two places that matter. This ticket is derived from the coat: it's a hash of the contents, so a different coat can never be handed back for it. And a ticket is worthless if the cloakroom has been emptied.

For reproducibility, a chain of custody. A sealed evidence bag with a label is evidence. An open bag with the same label is not. The commit ID is the label. The dirty flag says whether the bag was open. Where it breaks: unlike a seal, a dirty tree can be reconstructed exactly if you also keep the patch.

Put the two together and you have the sentence for the CTO: every row of the last table has a left column that can move and a right column that cannot. A record made of left-column values is a guess.

## DIAGRAM

**[DIAGRAM]** Two boxes. On the left the Git repository, cloned by everyone. On the right the data store. Draw the pointer file in the left box, then the arrow, then the objects in the store, one per version.

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

Look at the bottom line: the real file is in the working tree, ignored, and it's the tool, not Git, that checks it against the pointer. Now the ignore rule: everything under `data` is ignored except the pointer files.

**[ON SCREEN]** The root-cause box of section 28.7, shown after the "two results, one commit" step.

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

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch28/data-pointer`. The tool `tools/dataref.py` is the pattern in about a hundred lines of standard-library Python. The store is a directory beside the repository; in production it would be a bucket.

Into the lab. The tool here is the pattern in about a hundred lines of standard-library Python, and the store is a directory beside the repository.

**Step 1: add a data set by reference.** 🟢 SAFE for the Git side: the commit adds a five-line pointer.

```bash
git status --short --ignored data
python3 tools/dataref.py add data/raw/tickets.csv
cat data/raw/tickets.csv.ref
git status --short data
git add data/raw/tickets.csv.ref && git commit -q -m "Version the ticket data set by reference"
```

Predict: after the tool has run, which path will `git status` show as untracked? Say it out loud.

**[PAUSE]**

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

The data file was ignored before and stays ignored: the two exclamation marks in the first status. What becomes visible to Git is the pointer: five lines of JSON for a file of any size.

**Step 2: a new version of the data.** Four labelled tickets arrive. Predict what `git status` prints after the data file has changed.

**[PAUSE]**

```bash
git status --short
python3 tools/dataref.py verify
python3 tools/dataref.py add data/raw/tickets.csv
git diff
git commit -q -am "Add four labelled tickets to the data set"
```

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

Read the first two commands together. Four rows were appended, and `git status` printed nothing. The tool's own `verify` reports the mismatch. After the second `add`, the new version of the data is a two-line diff of the pointer: hash and size.

**Step 3: going back.** 🟢 SAFE: `git switch --detach` moves HEAD and rewrites tracked files, and refuses to overwrite local edits.

```bash
git switch -q --detach HEAD~1
python3 tools/dataref.py verify
python3 tools/dataref.py checkout
wc -l < data/raw/tickets.csv
git switch -q main && python3 tools/dataref.py checkout
```

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

Git moved the pointer. The working file still held the newer data until the tool restored the version the pointer names. Two steps.

**Step 4: a clone, and the store.**

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

A clone has pointers, not data. One `checkout` of the tool fetches the bytes and `verify` says ok. Now predict what happens when the store is gone.

**[PAUSE]**

<!-- snippet: ch28/data-pointer/06-store-is-the-risk -->
```text
# The pointer is only as good as the store behind it:
$ rm -r ../datastore/sha256 && rm data/raw/tickets.csv
$ python3 tools/dataref.py checkout
NOT IN STORE data/raw/tickets.csv sha256:4efbc43184d3
[exit status: 1]
```
<!-- /snippet -->

A pointer whose object is gone identifies a data set precisely and can't produce it. The store needs what the repository has: backups, access control, and a retention rule that never deletes an object some commit still points to.

**[TERMINAL]** Second replay: `labs/run ch28/run-record`.

**Step 5: a function that records the state.**

```bash
sed -n '19,34p' tools/runinfo.py
```

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

Four Git commands do the work, all 🟢 SAFE. `git rev-parse HEAD` gives the commit. `git status --porcelain=v1 -z` gives a stable, machine-readable list of what differs. Entries starting with two question marks are untracked files. `git diff HEAD --binary` is the complete uncommitted change to tracked files, and its SHA-256 identifies that change. `git describe --always --dirty --tags` gives a human-readable name.

Try it now, for thirty seconds. In any repository of yours, type `git describe --always --dirty --tags`. It only reads. Look at the end of the name it prints. I'll wait.

**[PAUSE]**

If the name ends in the word dirty, a tracked file differs from the last commit, and a run started now wouldn't be the code that the commit ID names. If it does not, check for untracked files as well. Step 8 shows why.

**Step 6: a recorded run.**

```bash
python3 evals/run_eval.py baseline
cat runs/baseline/run.json
```

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

Five identifiers in one file: the commit `aa18ad2` with `dirty: false`. The checksum of the data actually read, which you can compare with the pointer from step 1. A hash of the lock file. A hash of the configuration. And the resolved configuration itself, so that the record can be read without checking anything out.

**Step 7: two results, one commit.** Try an idea without committing it: one more keyword in the evaluation configuration.

```bash
git status --short
python3 evals/run_eval.py tuned
python3 evals/run_eval.py tuned --allow-dirty
```

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

The script refuses a tracked run from a dirty tree. That's the first defensible policy. With `--allow-dirty` it runs. Predict: what distinguishes the two run records?

**[PAUSE]**

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

Accuracy 0.8 and accuracy 0.9, both at commit `aa18ad2`. There are the two numbers from the opening, on one commit. A tracker that stores only the commit shows two runs of the same code with different results. This record tells them apart: `dirty: true`, a hash of the uncommitted diff, and the diff itself saved as `uncommitted.patch`. The last command proves the hash is of that diff. That's the second defensible policy: if dirty runs are allowed, log the status and the diff as artifacts. The root-cause box from the diagram section sums it up.

**Step 8: untracked files are a third state.**

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

`dirty` is false, because no tracked file changed, and `git diff HEAD` is empty. Yet a new module on the import path can change behavior. The function reports untracked files separately, and `--require-clean` refuses both. According to the report's reading of its source, the MLflow opt-in function doesn't count untracked files as dirty.

**[TERMINAL]** Third replay: `labs/run ch28/lab-33-3-reproduce-result`, the first four snippets. This is the lab you do as homework; we stop before its failure scenario.

**Step 9: today's number is not the recorded number.**

<!-- snippet: ch28/lab-33-3-reproduce-result/01-today -->
```text
$ git log --oneline --decorate -4
babb70d (HEAD -> main) Add slow and sync as technical keywords
bef8975 Add four labelled tickets to the data set
aa18ad2 (tag: v0.1.0) Add serving image definition and model pointer
8a681ec Add evaluation config, prompt and run recorder
$ python3 evals/run_eval.py today
run today: accuracy 0.7857 on 14 examples (commit babb70d)
$ cat ../tracker/baseline/metrics.json
{
  "accuracy": 0.8,
  "examples": 10
}
```
<!-- /snippet -->

Today, on `main`: 0.7857 on 14 examples. The tracker says 0.8 on 10. Don't guess. Read the record.

<!-- snippet: ch28/lab-33-3-reproduce-result/02-read-record -->
```text
$ grep -e "\"commit\"" -e "\"dirty\"" -e "\"describe\"" ../tracker/baseline/run.json
    "commit": "aa18ad2fb32ebcc4c1603d60d9aa1b6f3540b80e",
    "describe": "v0.1.0",
    "dirty": false,
$ grep -A2 "\"data\"" ../tracker/baseline/run.json
  "data": {
    "path": "data/raw/tickets.csv",
    "sha256": "2226b23c455b63565c71f01555c41bdd3661598f70cd2c989b0ddcd0164a898e"
--
    "data": "data/raw/tickets.csv",
    "default": "general",
    "keywords": {
```
<!-- /snippet -->

The record names a commit, says the tree was clean, and names the data by checksum.

**Step 10: reproduce beside your work.** 🟢 SAFE: `git worktree add --detach` creates a second working tree and doesn't touch the first.

<!-- snippet: ch28/lab-33-3-reproduce-result/03-worktree -->
```text
# Check the recorded commit out beside your work, without disturbing it:
$ commit=$(python3 -c "import json; print(json.load(open('../tracker/baseline/run.json'))['code']['commit'])")
$ git worktree add --detach ../repro "$commit"
Preparing worktree (detached HEAD aa18ad2)
HEAD is now at aa18ad2 Add serving image definition and model pointer
$ cd ../repro
$ python3 tools/dataref.py checkout
restored    data/raw/tickets.csv from sha256:2226b23c455b
restored    models/embedder.bin from sha256:7daca2095d04
$ grep sha256 data/raw/tickets.csv.ref
  "sha256": "2226b23c455b63565c71f01555c41bdd3661598f70cd2c989b0ddcd0164a898e",
```
<!-- /snippet -->

The worktree is at the recorded commit. The data tool restores the bytes the pointer at that commit names, and the checksum in the pointer equals the one in the run record.

<!-- snippet: ch28/lab-33-3-reproduce-result/04-rerun -->
```text
$ python3 evals/run_eval.py repro
run repro: accuracy 0.8000 on 10 examples (commit aa18ad2)
$ diff runs/repro/run.json ../tracker/baseline/run.json && echo "identical record"
identical record
```
<!-- /snippet -->

0.8000 on 10 examples, and the new run record is identical to the recorded one. That's what "reproduced" means: the same identifiers in, the same record out.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Recording only the commit ID of a run.** Root cause: `git rev-parse HEAD` names the last commit and says nothing about the index, the working tree or untracked files.
2. **Changing the data file and forgetting the pointer.** Root cause: the data file is ignored, so Git does not watch it, and only the tool's verify step compares it with the pointer.
3. **Treating the pointer as the backup.** Root cause: the pointer identifies the bytes and cannot produce them; the store is a dependency that can be emptied.
4. **Recording a model name, a registry alias or an image tag.** Root cause: each is a mutable reference, like a branch, and can name something else tomorrow.
5. **Ignoring the lock file because it is generated.** Root cause: it cannot be regenerated identically from what is in Git, since the package index changes, so it is an input.

## PRODUCTION EXAMPLE

Now, out of the lab. An evaluation team reports a ranking metric to a customer every quarter. A new engineer is asked to reproduce last quarter's number and cannot: the tracker names a commit, and the commit gives a different result.

The lead goes down the table of identifiers in order. Code: the commit exists. The tracker has no dirty flag, so the state of the tree is unknown. Dependencies: the repository has a lock file, committed. Data: the path is recorded, not a checksum, and the file at that path has been replaced twice since. Model: recorded as a registry alias, which has been promoted once since. Three of the rows were recorded as mutable references. The honest report to the customer is the one the root-cause box prescribes: the result can't be reproduced. Here's why. Here's the rerun from a commit with every identifier recorded.

The team then changes the evaluation entry point. It refuses to start a tracked run from a tree that is dirty or has untracked files, and it writes the commit, the data checksum from the pointer, the resolved model version and the resolved configuration into the run record.

## PRACTICE EXERCISE

Your turn. Do Lab 33.2, "Version a dataset by reference", in [`lab-manual/m33-ai-ml-workflows.md`](../../lab-manual/m33-ai-ml-workflows.md).

Before you change the data file in the lab, predict what `git status --short` will print and what the tool's verify step will print. Before the lab's failure scenario, write down how a pointer and a file can come to disagree without any error, and which command would have shown it. The lab's questions are answered in a separate file. Attempt them first.

The challenge is Exercise 33.7, Level 5, "The number in the paper cannot be reproduced", in [`exercises/m32-m34-practice.md`](../../exercises/m32-m34-practice.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q370: "A run in the tracker names a commit. You check it out and get a different metric. List every cause you can think of, in the order you would test them, and the evidence for each."

**[PAUSE]**

Answer out loud. The question asks for three things per cause: the cause, its place in an order, and its evidence. A strong answer uses the rows of the identifier table as its list, so that nothing is forgotten: code state beyond the commit, dependencies, environment, data, model, configuration. It justifies the order, for example by how cheap each test is and how often each cause occurs. For each cause it names the record or the command that would confirm or exclude it. And it says plainly what you report when the evidence needed for a cause was never recorded.

## RECAP

Let's land this, in your own words.

- A large file is versioned by committing a pointer that names it by checksum, with the bytes in a content-addressed store.
- Git LFS, DVC and a hand-made pointer share hash, store and pointer; they differ in how the bytes follow when the pointer moves.
- The pointer and the file can disagree without Git noticing, and the store can be lost.
- A run is identified by the commit, the dirty state and diff, untracked files, the data and model versions, the resolved configuration and the environment.
- Record immutable identifiers: full commit ID, lock file, image digest, data checksum, model version or hub commit hash, resolved configuration.

## HOMEWORK

Read sections 28.6 to 28.8. Do Lab 33.3, "Reproduce a past result from its recorded identifiers", in [`lab-manual/m33-ai-ml-workflows.md`](../../lab-manual/m33-ai-ml-workflows.md), including its failure scenario, which this video didn't show. Then do Exercise 33.4, Level 3, "Three runs, one commit ID", and Exercise 33.5, Level 3, "The pointer and the file disagree", in [`exercises/m32-m34-practice.md`](../../exercises/m32-m34-practice.md).

Today you versioned data without putting it in Git, and you reproduced a result from its record, to the last digit. If the list of identifiers feels long, that's normal: the table has six rows, and you can keep it beside you. Next time: gitignore and gitattributes for ML projects, pre-commit backed by CI, and a professional AI project repository. Until then, look at the state first and type second. See you in the next one.
