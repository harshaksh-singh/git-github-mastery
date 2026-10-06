# V087: .gitattributes: per-path settings that travel, and line endings

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 14, Worktrees, attributes, hooks, stash internals, rerere
- **Planned minutes.** 20
- **Prerequisites.** V012, V014
- **Textbook sections.** [Chapter 14C](../../textbook/ch14c-stash-rerere-attributes-hooks.md), sections 14C.4 and 14C.5
- **Demo scripts.** `labs/ch14c/attr-basics.sh`, `labs/ch14c/attr-eol.sh`

## HOOK

**[ON SCREEN]** A pull request: 1 file changed, 412 insertions, 412 deletions. The author says: "I changed one line."

Both statements are true. A colleague on Windows opened the file; the editor wrote it back with CRLF line endings; and now every line differs from what the repository stores. Review is impossible, blame for that file is ruined, and the next merge of any other branch that touched the file will conflict on every line.

The team's first fix is a chat message: "everyone, please set `core.autocrlf`". Three weeks later it happens again, with a contractor who never saw the message. A configuration value covers what one person adds on one machine. The team needed something that is part of the project.

## INTRODUCTION

You met line endings as a symptom in the working-tree part of the course, and you wrote ignore rules in `.gitignore`. Today's file looks like a sibling of `.gitignore` and is something else: `.gitattributes` does not decide whether Git tracks a path. It decides how Git treats the content of a path when it converts, compares, merges or archives it.

This video covers the mechanism and its first application, line endings. The next one covers the three kinds of driver that attributes can name. One sentence connects both, and you should be able to say it by the end: the attribute travels, the driver does not.

## LEARNING OBJECTIVES

**[ON SCREEN]** After this video you can:

- say which attribute applies to a path and from which file it comes;
- explain "the attribute travels, the driver does not";
- normalize line endings in a repository with `text` and `eol`, and predict what the next `git status` shows;
- renormalize existing files in one commit;
- explain what `core.autocrlf` cannot do that attributes do.

## CONCEPT

In one sentence: a `.gitattributes` file attaches named attributes to paths, and Git consults them whenever it converts, compares, merges or archives a file. The file is versioned and reaches every clone, while the programs that some attributes name are defined in configuration and reach nobody.

Precisely. Each line is a pattern followed by attributes. For one path, an attribute is in one of four states.

**[ON SCREEN]** The state table of section 14C.4.

| Written as | State | `git check-attr` prints |
|---|---|---|
| `text` | set | `set` |
| `-text` | unset | `unset` |
| `eol=lf` | set to a value | the value |
| not mentioned, or `!text` | unspecified | `unspecified` |

Patterns follow the rules of `.gitignore` with two exceptions: negative patterns are forbidden, and a pattern that matches a directory does not apply to the files inside it. Within one file a later line overrides an earlier one, per attribute. Between files, the order of precedence is: first `.git/info/attributes`, which is local to this clone and not versioned. Then the `.gitattributes` in the directory of the path, then those of its parent directories, the nearer the stronger. Then the file named by `core.attributesFile`. Then the system-wide file.

A macro attribute sets several others at once. The one built-in macro is `binary`, defined as `-diff -merge -text`.

Inside `.git`: nothing, unless you use `.git/info/attributes`. A `.gitattributes` file is an ordinary tracked file.

Which attributes need configuration? `text`, `eol`, `export-ignore`, `-diff`, `-merge`, the built-in diff patterns and the built-in merge drivers work from the attribute alone. `diff=`, `merge=` and `filter=` with names of your own need a definition in configuration. That is the next video.

**Line endings.** In one sentence: a path with the `text` attribute is stored with LF line endings in the repository whatever its endings are on disk; `eol` chooses the endings that a checkout writes; and `* text=auto` lets Git decide per file which files are text.

**[ON SCREEN]** The conversion table of section 14C.5.

| `text` is | On `git add` | On checkout |
|---|---|---|
| set | CRLF becomes LF, always | LF becomes CRLF if `eol=crlf` (or the platform default says so) |
| unset (`-text`) | bytes are stored as they are | bytes are written as they are |
| `auto` | as "set" if Git judges the content to be text **and** the file is not already stored with CRLF | the same condition |
| unspecified | `core.autocrlf` decides | `core.autocrlf` and `core.eol` decide |

Read the third row again. With `auto`, a file that is already stored with CRLF is left alone. So introducing `text=auto` does not by itself rewrite a project.

`core.autocrlf` is the older, per-user mechanism. `true` converts in both directions, `input` only on the way in. It is not deprecated. It is not a team policy either.

The deliberate rewrite is 🟡 CAUTION: `git add --renormalize .`. It applies the current conversion to every tracked file and stages the result. The working tree, HEAD and the branch are unchanged; new blobs are written where the stored form changes. Preview with `git status` before committing; undo the staging with `git restore --staged .`.

When to be careful. The renormalizing commit touches every line of every converted file. Make it a commit of its own, announce it, merge open branches first where you can, and list its ID in the file that blame's ignore-revs option reads. Unmerged work will conflict on those files; `git merge -X renormalize`, or `merge.renormalize=true`, normalizes all three versions before merging and removes the conflicts that come from the conversion alone. And mark files that must keep their bytes, vendor exports, fixtures with deliberate CRLF, everything binary, with `-text` or `binary`.

## MENTAL MODEL

The textbook's analogy: labels on folders in a shared filing cabinet. "Text". "Do not merge". "Show through viewer X". Everyone sees the labels, because the labels are in the cabinet.

Whether viewer X exists is a matter of each reader's own desk. And here the analogy breaks: a missing viewer produces no complaint.

For line endings, the labels need no viewer. `text` and `eol` are understood by every Git. That is why line-ending policy in `.gitattributes` works for the contractor who never read the chat message.

## DIAGRAM

**[DIAGRAM]** One file's bytes in three places, before and after the attribute. The columns are the ones `git ls-files --eol` prints: `i/` for the index, `w/` for the working tree, `attr/` for the attributes in force.

```text
  sample.csv          repository and index          working tree            attributes in force
  ------------------  ----------------------------  ----------------------  ----------------------
  before              i/crlf   (stored with CRLF)   w/crlf                  attr/      (none)
  after the commit    i/lf     (stored with LF)     w/crlf  on every OS     attr/text eol=crlf

  loader.py
  ------------------  ----------------------------  ----------------------  ----------------------
  before              i/crlf                        w/crlf                  attr/      (none)
  text=auto only      i/crlf   (left alone: it is   w/crlf                  attr/text=auto
                               already stored CRLF)
  after renormalize   i/lf                          w/crlf until rewritten  attr/text=auto
  after a checkout    i/lf                          w/lf  on this Mac       attr/text=auto
```

Two files, two fates. `sample.csv` has an explicit `eol=crlf`: stored with LF, checked out with CRLF everywhere. `loader.py` falls under `text=auto`: untouched until the renormalization, then stored with LF and checked out in the platform's form.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14c/attr-basics`. A training repository with two attribute files.

```bash
cat .gitattributes
cat data/.gitattributes
```

<!-- snippet: ch14c/attr-basics/01-files -->
```text
$ cat .gitattributes
# pattern     attributes
*             text=auto
*.sh          text eol=lf
*.csv         text eol=crlf
*.bin         binary
CHANGELOG.md  merge=union
docs          export-ignore
.gitattributes export-ignore
$ cat data/.gitattributes
# Vendor exports: keep every byte as delivered.
*.csv  -text
```
<!-- /snippet -->

Seven lines at the top: a default of `text=auto`, shell scripts with LF, CSV files with CRLF, binaries, a merge driver for the changelog, and two `export-ignore` lines. And a second file in `data/`.

🟢 SAFE: `git check-attr` answers "which attributes does Git see for this path". It is the first diagnostic for every problem in this video and the next.

```bash
git check-attr -a -- src/train.py scripts/run.sh data/encoder.bin
git check-attr text eol merge -- src/train.py
```

Predict what `data/encoder.bin` shows. It matches two lines: the star and `*.bin`.

<!-- snippet: ch14c/attr-basics/02-check-attr -->
```text
$ git check-attr -a -- src/train.py scripts/run.sh data/encoder.bin
src/train.py: text: auto
scripts/run.sh: text: set
scripts/run.sh: eol: lf
data/encoder.bin: binary: set
data/encoder.bin: diff: unset
data/encoder.bin: merge: unset
data/encoder.bin: text: unset
# Ask for named attributes to see the unspecified state as well:
$ git check-attr text eol merge -- src/train.py
src/train.py: text: auto
src/train.py: eol: unspecified
src/train.py: merge: unspecified
```
<!-- /snippet -->

The later line won for `text`, and the macro `binary` expanded into three unset attributes: `diff`, `merge` and `text`. With `-a` you see only what is specified; ask for named attributes to see the unspecified state as well.

Now precedence. The same pattern, one file at the top and one below `data/`.

```bash
git check-attr text eol -- labels.csv data/labels.csv
printf 'data/labels.csv text eol=lf\n' > .git/info/attributes
git check-attr text eol -- data/labels.csv
```

<!-- snippet: ch14c/attr-basics/03-precedence -->
```text
# The same pattern, one file at the top and one below data/:
$ git check-attr text eol -- labels.csv data/labels.csv
labels.csv: text: set
labels.csv: eol: crlf
data/labels.csv: text: unset
data/labels.csv: eol: crlf
# .git/info/attributes is not versioned and beats every .gitattributes file:
$ printf 'data/labels.csv text eol=lf\n' > .git/info/attributes
$ git check-attr text eol -- data/labels.csv
data/labels.csv: text: set
data/labels.csv: eol: lf
$ rm .git/info/attributes
```
<!-- /snippet -->

For `data/labels.csv` the file in `data/` unset `text`, and `eol` still comes from the top-level file. Precedence is decided attribute by attribute. Then `.git/info/attributes`, which is not versioned, overrode both.

One attribute that concerns none of the conversions.

```bash
git ls-files
git archive --format=tar HEAD | tar -tf -
```

<!-- snippet: ch14c/attr-basics/04-export-ignore -->
```text
$ git ls-files
.gitattributes
data/.gitattributes
data/encoder.bin
data/labels.csv
docs/design.md
labels.csv
scripts/run.sh
src/train.py
$ git archive --format=tar HEAD | tar -tf -
data/
data/encoder.bin
data/labels.csv
labels.csv
scripts/
scripts/run.sh
src/
src/train.py
```
<!-- /snippet -->

`docs` and both attribute files are tracked and absent from the archive. `export-ignore` is for what belongs in the repository and not in a release tarball.

**[ON SCREEN]** Lower third: **GitHub**. GitHub reads `.gitattributes` for purposes of its own, such as the `linguist-` attributes for language statistics and collapsed diffs. Those names mean nothing to Git.

**[TERMINAL]** Replay `labs/run ch14c/attr-eol`. A teammate on Windows committed two files with CRLF.

```bash
git ls-files --eol
```

<!-- snippet: ch14c/attr-eol/01-before -->
```text
$ git ls-files --eol
i/crlf  w/crlf  attr/                 	loader.py
i/lf    w/lf    attr/                 	run.sh
i/crlf  w/crlf  attr/                 	sample.csv
```
<!-- /snippet -->

`loader.py` and `sample.csv` are `i/crlf`: CRLF in the repository. The `attr/` column is empty. First, the personal setting.

```bash
git -c core.autocrlf=input add clean.py
git ls-files --eol clean.py loader.py
```

<!-- snippet: ch14c/attr-eol/02-autocrlf -->
```text
# A personal setting converts what YOU add from now on:
$ printf 'def clean(row):\r\n    return row.strip()\r\n' > clean.py
$ git -c core.autocrlf=input add clean.py
warning: in the working copy of 'clean.py', CRLF will be replaced by LF the next time Git touches it
$ git ls-files --eol clean.py loader.py
i/lf    w/crlf  attr/                 	clean.py
i/crlf  w/crlf  attr/                 	loader.py
# It does not touch a file that is already stored with CRLF, and a teammate without the setting
# still commits CRLF:
$ printf 'def split(row):\r\n    return row.split()\r\n' > split.py
$ git add split.py
$ git ls-files --eol split.py
i/crlf  w/crlf  attr/                 	split.py
```
<!-- /snippet -->

Your setting normalized the file you added: `clean.py` is `i/lf`. It did not touch `loader.py`, which is already stored with CRLF. And the rest of the snippet shows a commit made without the setting: `split.py` goes in with CRLF. That is the two things `core.autocrlf` cannot do.

Now the attributes.

**[PAUSE]** You write three lines into `.gitattributes`. You have edited no other file. Predict what `git status -s` shows.

```bash
printf '* text=auto\n*.sh text eol=lf\n*.csv text eol=crlf\n' > .gitattributes
git status -s
git add --renormalize .
git status -s
```

<!-- snippet: ch14c/attr-eol/03-attributes -->
```text
$ printf '* text=auto\n*.sh text eol=lf\n*.csv text eol=crlf\n' > .gitattributes
$ git status -s
 M sample.csv
?? .gitattributes
$ git add --renormalize .
$ git status -s
M  loader.py
M  sample.csv
M  split.py
?? .gitattributes
$ git diff --cached --stat
 loader.py  | 4 ++--
 sample.csv | 4 ++--
 split.py   | 4 ++--
 3 files changed, 6 insertions(+), 6 deletions(-)
```
<!-- /snippet -->

`sample.csv` is modified, although you did not touch it. It now has `text` set, so its stored CRLF no longer matches what Git would store. `loader.py` and `split.py` fall under `text=auto` and are left alone, because they are already stored with CRLF. After `git add --renormalize .`, all three are staged.

```bash
git add .gitattributes
git commit -q -m "Normalize line endings with .gitattributes"
git ls-files --eol
```

<!-- snippet: ch14c/attr-eol/04-after -->
```text
$ git add .gitattributes
$ git commit -q -m "Normalize line endings with .gitattributes"
$ git ls-files --eol
i/lf    w/lf    attr/text=auto        	.gitattributes
i/lf    w/crlf  attr/text=auto        	clean.py
i/lf    w/crlf  attr/text=auto        	loader.py
i/lf    w/lf    attr/text eol=lf      	run.sh
i/lf    w/crlf  attr/text eol=crlf    	sample.csv
i/lf    w/crlf  attr/text=auto        	split.py
```
<!-- /snippet -->

Every file is `i/lf` now, and the `attr/` column says why. The working tree column still shows CRLF for several files: files on disk keep their endings until Git writes them again.

```bash
rm loader.py sample.csv split.py
git restore .
git ls-files --eol
```

<!-- snippet: ch14c/attr-eol/05-fresh-checkout -->
```text
# The index now holds LF. Files on disk keep their old endings until they are written again:
$ rm loader.py sample.csv split.py
$ git restore .
$ git ls-files --eol
i/lf    w/lf    attr/text=auto        	.gitattributes
i/lf    w/crlf  attr/text=auto        	clean.py
i/lf    w/lf    attr/text=auto        	loader.py
i/lf    w/lf    attr/text eol=lf      	run.sh
i/lf    w/crlf  attr/text eol=crlf    	sample.csv
i/lf    w/lf    attr/text=auto        	split.py
```
<!-- /snippet -->

`git restore .` here writes back files that the script deleted a line earlier; in general it is 🔴 DANGEROUS, because it overwrites uncommitted edits in the working tree. The rewritten `loader.py` and `split.py` have LF on this Mac. `sample.csv` has CRLF on every platform because of `eol=crlf`. And `clean.py`, which was not rewritten, keeps its CRLF.

**[ON SCREEN]** "Outdated advice": "Set `core.autocrlf` and you are done." The setting is a convenience for one user. The textbook cites the Git FAQ, which recommends marking text and binary files in `.gitattributes`, and the attributes manual, which gives the procedure you saw: `* text=auto`, then one `git add --renormalize .`.

## COMMON MISTAKES

1. **Making `core.autocrlf` the team's line-ending policy.** Root cause: it is configuration, which covers what one person adds on one machine and is not cloned.
2. **Expecting `* text=auto` to fix files that are already stored with CRLF.** Root cause: with `auto`, Git leaves a file alone when it is already stored with CRLF; the rewrite is `git add --renormalize`.
3. **Mixing the renormalization into a feature commit.** Root cause: it touches every line of every converted file, which hides the feature and ruins blame unless the commit stands alone and is listed for `--ignore-revs-file`.
4. **A directory pattern that seems not to apply.** Root cause: a pattern that matches a directory does not apply to the files inside it; write `docs/**`.
5. **Guessing which rule applies to a path.** Root cause: precedence is per attribute and across several files; `git check-attr -a -- <path>` reports what Git sees.

## PRODUCTION EXAMPLE

A data team with engineers on macOS and Windows keeps Python sources, shell scripts and vendor CSV exports in one repository. After the third pull request in which every line of a file changed, the lead schedules the normalization.

She merges the open branches she can. She commits a `.gitattributes` with `* text=auto`, `*.sh text eol=lf`, and `-text` for the vendor exports, which must keep their bytes. She runs `git add --renormalize .`, reads `git status` before committing, and makes the result one commit with nothing else in it. The commit's ID goes into the ignore-revs file that blame reads. The two branches that could not be merged first are merged afterwards with `-X renormalize`, which removes the conflicts that come from the conversion alone. The announcement to the team says what will show as modified after the next pull and why.

## PRACTICE EXERCISE

Do Exercise 14.2, Level 1, "Attributes that travel with the repository", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

Before every `git check-attr`, write the state you expect for each attribute: set, unset, a value, or unspecified, and the file it comes from. Before you add the attribute file, predict which paths `git status` will show as modified without having been edited.

The challenge is Exercise 14.5, Level 2, "A changelog that conflicts on every merge", in the same file. It needs the next video for one of its answers.

## INTERVIEW QUESTION

**[ON SCREEN]** Q58: "Your team adds `* text=auto` to a five-year-old repository. What does the next `git status` show, what does `git add --renormalize .` do, and how do you protect open branches and `git blame`?"

Pause and answer aloud.

A strong answer does not say "everything shows as modified". It distinguishes what `auto` does with files that are already stored with CRLF from what an explicit `text` does, and predicts `git status` accordingly. It describes the renormalization by what it changes: the index and new blobs, not the working tree. It then gives a rollout: a commit of its own, the order relative to open branches, the merge option that removes conversion-only conflicts, and the mechanism that keeps blame useful. It finishes with the files that must be excluded and how.

## RECAP

You should now be able to say:

- `.gitattributes` is a tracked file that attaches attributes to paths; `git check-attr` tells me which apply and precedence is decided per attribute.
- The attribute travels with the repository; a program it names is configuration and does not.
- `text` stores LF in the repository, `eol` chooses the checkout form, and `text=auto` leaves files that are already stored with CRLF alone.
- `git add --renormalize .` is the deliberate rewrite, in one commit of its own.
- `core.autocrlf` is a per-user convenience and cannot be a team policy.

## HOMEWORK

Read sections 14C.4 and 14C.5 of [Chapter 14C](../../textbook/ch14c-stash-rerere-attributes-hooks.md).
