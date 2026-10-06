# V035: Conflict types beyond content: renames, modify/delete, add/add, binary, directories

- **Part:** 2, Integration and collaboration mechanics
- **Module:** 6, Divergence and merge
- **Planned minutes:** 26
- **Prerequisites:** V034
- **Textbook sections:** [Chapter 8](../../textbook/ch08-merge.md), section 8.11
- **Demo scripts:** `labs/ch08/conflict-rename.sh`, `labs/ch08/conflict-modify-delete.sh`, `labs/ch08/conflict-add-add.sh`, `labs/ch08/conflict-binary.sh`, `labs/ch08/conflict-directory-rename.sh`, `labs/ch08/conflict-file-directory.sh`

## HOOK

**[ON SCREEN]** One line of Git output: `CONFLICT (modify/delete): evalkit/metrics.py deleted in refactor/score-objects and modified in HEAD.`

You merge a refactoring branch. Git reports a conflict and says that the other side deleted the metrics module. You open the file to look for the markers. There are none. You ask Ravi why he deleted the module, and he says he didn't delete anything. He moved it and rewrote part of it.

Both of you are telling the truth, and so is Git. A merge that stops without markers is the one that stops engineers, because the routine from the last video, open the file and edit between the markers, has nothing to hold on to. This video replaces that routine with a better one: read the type, read the stages, then decide. Keep Ravi's answer in mind. One number on screen will explain it.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. A merge joins another branch's history into yours, and a conflict is a path where Git can't decide the result on its own. So far every conflict you've seen was a content conflict: two sides changed the same lines, and Git wrote marker blocks into the file. That's one type out of eight in this chapter's table.

Today you meet the others: add against add, modify against delete, the three rename cases, binary files, a file against a directory, and a directory rename. For each one you do the same three things. You read the word in parentheses after `CONFLICT`. You read the two letters in `git status --short`. And you read which stages exist in the index, Git's draft of the next commit, with `git ls-files -u`. Those three readings tell you which command resolves the path.

Everything here is Git, on your machine. The project is `evalkit`.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

**[ON SCREEN]** The five objectives.

After this video you can:

- Name the conflict type from the line `git status` prints.
- Resolve a rename against an edit and explain the role of the similarity threshold.
- Resolve a modify/delete conflict in either direction from the stages that exist.
- Resolve a conflict in a binary file by choosing a version.
- Explain a directory-rename conflict and the setting that controls its detection.

## CONCEPT

**[ANIMATION]** graph: 6ae3c51-e5b08ff main; 6ae3c51-727adba refactor/scoring-module; HEAD=main; role:6ae3c51:base; role:e5b08ff:ours; role:727adba:theirs => + note:e5b08ff:an_edit; note:727adba:a_rename; say:Detection_succeeds:_the_edit_arrives_in_the_renamed_file => + say:Below_50_percent_similarity_Git_sees_a_deletion_and_an_addition title=Base,_ours_and_theirs id=history

**[ANIMATION]** step: state-1

Why are there types at all? Because the three-way rule works on paths before it works on lines. For each path Git looks at three things: what the base had, what ours has, what theirs has. Here's one small history from today's demo, with its branch names. `6ae3c51` is the base. `e5b08ff`, on `main`, is ours. `727adba`, on a refactoring branch, is theirs.

**[ANIMATION]** walk: id=stages columns=stage_1_base,stage_2_ours,stage_3_theirs,what_it_tells_you rows=yes:yes:yes:content_conflict|-:yes:yes:both_sides_added_the_path|yes:yes:-:they_deleted_it|-:-:yes:Git_proposes_a_location|yes:yes:yes:binary,_no_markers mono=off last=what_it_tells_you title=Which_stages_exist? at_2=45 at_3=62 at_4=80

**[ANIMATION]** step: 1

A content conflict is the case where all three have the file and both sides changed it in overlapping places. But a path may also be missing on one side, missing in the base, or present under a different name. Each of those combinations is a conflict type, and most of them never read a line of the file.

**[ANIMATION]** say: The_word_in_parentheses_after_CONFLICT_names_the_type

That gives you the first fact of this video, in the textbook's words: the word in parentheses after `CONFLICT` names the type, and only some types put markers in a file.

**[ANIMATION]** step: 4

The second fact is about the stages, the numbered slots of an index entry. Stage 1 is the base, stage 2 is ours, stage 3 is theirs. In a content conflict all three exist. In the other types some are absent, and the absence is the information. No stage 1 means there was no common version: both sides added the path. No stage 3 means "their version" is no file: they deleted it. One stage alone, on a path you didn't create, means Git is proposing a location.

**[ANIMATION]** step: history.state-2

The third fact is about renames. Git does not record renames. A tree, Git's listing of one directory, stores names and blob IDs, nothing else. A blob is the stored content of one file. The merge detects a rename by comparing content, with the same 50 percent similarity threshold as `git diff`. When detection succeeds, a rename on one side and an edit on the other is no conflict at all: your edit arrives in the renamed file. That's the history on screen: `e5b08ff` is an edit, and `727adba` is a rename. When detection fails, the same change looks like a deletion and an unrelated addition, and you get the conflict from the hook.

**[ANIMATION]** step: history.state-3

When does detection fail? When a move and a rewrite land in one commit, so that less than half of the content survives under the new name. A rename is an inference from similarity, and every inference needs a cutoff.

**[ANIMATION]** step: stages.5

The fourth fact is about binary files. Git can't merge them line by line. It reports the conflict as a content conflict, records all three stages, leaves your version in the working tree and writes no markers.

**[ANIMATION]** cards: cards=git_add:this_path_exists_in_the_result,_with_this_content|git_rm:this_path_does_not_exist_in_the_result title=Two_resolving_commands at_1=25 at_2=45

And the resolving commands follow from the stages. `git add` means "this path exists in the result, with this content". `git rm` means "this path does not exist in the result". Every type in today's table is resolved with some combination of those two, sometimes after choosing a stage.

## MENTAL MODEL

**[ON SCREEN]** "A merge asks one question per path: what should be at this name?"

A picture helps. Two people reorganize the same filing cabinet from the same starting inventory.

**[ANIMATION]** walk: columns=one_person,the_other rows=rewrote_a_paragraph:rewrote_the_same_paragraph|moved_a_document:shredded_it|filed_a_new_document:filed_one_under_the_same_label|relabelled_a_whole_drawer:dropped_a_document_into_the_old_drawer mono=off title=One_filing_cabinet,_two_people captions=off at_1=3 at_2=33 at_3=48 at_4=60

**[ANIMATION]** step: 4

A content conflict is both of them rewriting the same paragraph of one document. The other types are about the folders. One person moved a document while the other shredded it. Both filed a new document under the same label. One relabelled a whole drawer while the other dropped a new document into the old drawer. Nobody needs to read a paragraph to see those problems. They need the inventory.

**[ANIMATION]** step: stages.5

The stages are that inventory. So the model is: for a conflict without markers, the index is the conflict.

**[ANIMATION]** stores: boxes=one_snapshot:names_and_blob_IDs|the_other_snapshot:names_and_blob_IDs rows=1:A:evalkit/metrics.py|2:B:evalkit/scoring.py@hl arrows=3:A1>B1:50%_similar? mono=on title=Two_snapshots_and_a_threshold at_1=30 at_2=42 at_3=55

Where the picture breaks: a person who moves a document knows they moved it. Git does not. It sees a name that vanished and a name that appeared, and it infers a move only when the two contents are at least 50 percent similar. The filing clerk has a memory. Git has two snapshots and a threshold.

## DIAGRAM

**[DIAGRAM]** Build the table row by row during the demo; each row appears when its transcript has been read. It is the table of section 8.11.

```text
Type              status --short            Stages     Working tree           Resolve with
----------------  ------------------------  ---------  ---------------------  ---------------------------
content           UU                        1, 2, 3    marker blocks          edit, git add
add/add           AA                        2, 3       one block, both files  edit or choose, git add
modify/delete     UD (deleted by them)      1 + the    modified version,      git add to keep,
                  DU (deleted by us)        modifier   no markers             git rm to delete
rename/rename     DD old, AU ours, UA       one per    both new files         git add one name,
                  theirs                    path                              git rm the other two
rename/delete     UD on the new name        1, 2       the renamed file       git add or git rm
binary            UU                        1, 2, 3    our version,           pick a stage or
(as content)                                           no markers             regenerate, git add
file/directory    AU on a renamed path      2          file moved aside,      rename, git add, git rm
                                                       directory in place
file location     UA on the suggested path  3          file at the            git add to accept,
                                                       suggested path         or move it
```

Here's the whole video in one table, eight types. Don't memorise it yet. We fill it in row by row in the demo.

**[ANIMATION]** walk: id=box columns=line,the_conflict_from_the_hook rows=Observed:CONFLICT_(modify/delete),_though_nobody_decided_to_delete_the_module|Git_state:their_scoring.py_shares_39%_of_its_content|Mechanism:below_50%_similarity_Git_sees_a_deletion_and_an_addition|Root_cause:a_move_and_a_rewrite_in_one_commit|Why:trees_store_names_and_blob_IDs,_a_rename_is_an_inference|Fix:merge_again_with_-X_find-renames=30%,_or_port_the_edit_by_hand|Prevention:land_the_move_as_its_own_change_first mono=off title=The_root-cause_box at_1=15

**[ANIMATION]** step: 1

**[DIAGRAM]** Then the root-cause box of section 8.11, one line at a time, after the `below-threshold` snippet.

```text
Observed behavior : CONFLICT (modify/delete) on evalkit/metrics.py, although nobody decided to
                    delete the module. The new evalkit/scoring.py is staged without your edit.
Git state         : Theirs has no metrics.py and a scoring.py that shares 39% of its content.
Mechanism         : Rename detection pairs a deleted path with an added path only when their
                    similarity reaches the threshold, 50% by default. Below that, Git sees a
                    deletion and an addition.
Root cause        : A move and a rewrite in one commit. The snapshot holds no rename, only two
                    paths with different content.
Why Git does this : Trees store names and blob IDs. A rename is an inference from similarity,
                    and every inference needs a cutoff.
Correct fix       : Abort and merge again with -X find-renames=30%, or port your edit into the
                    new file by hand and git rm the old path.
Prevention        : Land the move as its own change and merge it into every open branch before
                    the rewrite starts. Two commits on one branch are not enough for the
                    merge, which compares only the tips, though they keep git log --follow
                    working.
```

And this box belongs to the conflict from the hook. It comes back in the demo.

## LIVE TERMINAL DEMO

**[TERMINAL]** Six replays. For each one the rule is the same: read the `CONFLICT` line, name the type, then look at the stages.

**add/add.** `labs/run ch08/conflict-add-add`. Both branches created `evalkit/cache.py` with different content.

```bash
git merge feature/disk-cache
git status --short
git ls-files -u
```

Predict which stages exist. Say it out loud. I'll wait.

**[PAUSE]**

<!-- snippet: ch08/conflict-add-add/01-merge -->
```text
$ git merge feature/disk-cache
Auto-merging evalkit/cache.py
CONFLICT (add/add): Merge conflict in evalkit/cache.py
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
AA evalkit/cache.py
$ git ls-files -u
100644 7f040298ad3ac9af50f69563114d5f3f5fff3576 2	evalkit/cache.py
100644 8d7d969205f3f1edf8a7f316f04e2481e6df6a31 3	evalkit/cache.py
$ git show :1:evalkit/cache.py
fatal: path 'evalkit/cache.py' is in the index, but not at stage 1
hint: Did you mean ':2:evalkit/cache.py'?
[exit status: 128]
```
<!-- /snippet -->

`AA`, stages 2 and 3, and asking for stage 1 fails: the path is in the index, but not at stage 1. There was no common version. This type does write markers, one block holding both whole files.

<!-- snippet: ch08/conflict-add-add/02-file -->
```text
$ cat evalkit/cache.py
<<<<<<< HEAD
_CACHE = {}


def load(key):
    return _CACHE.get(key)
=======
import json


def load(path):
    with open(path) as f:
        return json.load(f)
>>>>>>> feature/disk-cache
```
<!-- /snippet -->

Look at the two halves. One is an in-memory cache, the other loads JSON from disk. Two modules with the same name are usually two answers to one need. The resolution is a design conversation, not an edit.

**modify/delete.** `labs/run ch08/conflict-modify-delete`. You edited `scripts/legacy_eval.sh`, and the cleanup branch deleted it.

<!-- snippet: ch08/conflict-modify-delete/01-merge -->
```text
$ git merge cleanup/remove-legacy
CONFLICT (modify/delete): scripts/legacy_eval.sh deleted in cleanup/remove-legacy and modified in HEAD.  Version HEAD of scripts/legacy_eval.sh left in tree.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status
On branch main
You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Unmerged paths:
  (use "git add/rm <file>..." as appropriate to mark resolution)
	deleted by them: scripts/legacy_eval.sh

no changes added to commit (use "git add" and/or "git commit -a")
```
<!-- /snippet -->

Read the `CONFLICT` line to the end: "Version HEAD of scripts/legacy_eval.sh left in tree." Git keeps the edited version in the working tree and waits. The long status says "deleted by them".

<!-- snippet: ch08/conflict-modify-delete/02-stages -->
```text
$ git status --short
UD scripts/legacy_eval.sh
$ git ls-files -u
100644 4a41a25aa3c40cf94e023b2f4e69974e8d1b0e5f 1	scripts/legacy_eval.sh
100644 26610f62ce9e5b2744199a6dd9e966eb004ca890 2	scripts/legacy_eval.sh
$ ls scripts
legacy_eval.sh
```
<!-- /snippet -->

`UD`, stages 1 and 2. Stage 3 does not exist. Now a question about the shortcuts from the last video. What do `git checkout --theirs` and `git restore --theirs` 🔴 do with a path that has no "their version"? Say it out loud.

**[PAUSE]**

<!-- snippet: ch08/conflict-modify-delete/03-restore-vs-checkout -->
```text
# Stage 3 does not exist for this path. The two commands react differently:
$ git checkout --theirs scripts/legacy_eval.sh
error: path 'scripts/legacy_eval.sh' does not have their version
[exit status: 1]
$ git restore --theirs scripts/legacy_eval.sh
[exit status: 0]
$ test -f scripts/legacy_eval.sh
[exit status: 1]
$ git status --short
UD scripts/legacy_eval.sh
$ git restore --ours scripts/legacy_eval.sh
$ test -f scripts/legacy_eval.sh
[exit status: 0]
$ git restore --merge scripts/legacy_eval.sh
error: path 'scripts/legacy_eval.sh' does not have all necessary versions
[exit status: 1]
```
<!-- /snippet -->

They disagree. `git checkout --theirs` refuses: the path does not have their version. `git restore --theirs` succeeds silently, exit status 0, and the `test -f` after it fails: the file is gone from the working tree. Restoring "their version" of a path that they deleted means deleting it. Neither command marks the path as resolved. It's still `UD`. And `git restore --merge` can't rebuild a marker file, because the path does not have all necessary versions.

From the branch that did the deleting, the same conflict has the letters the other way round.

<!-- snippet: ch08/conflict-modify-delete/04-deleted-by-us -->
```text
$ git merge main
CONFLICT (modify/delete): scripts/legacy_eval.sh deleted in HEAD and modified in main.  Version main of scripts/legacy_eval.sh left in tree.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
DU scripts/legacy_eval.sh
$ git ls-files -u
100644 4a41a25aa3c40cf94e023b2f4e69974e8d1b0e5f 1	scripts/legacy_eval.sh
100644 26610f62ce9e5b2744199a6dd9e966eb004ca890 3	scripts/legacy_eval.sh
# Decision on this branch: keep the edited file.
$ git add scripts/legacy_eval.sh
$ git status --short
A  scripts/legacy_eval.sh
```
<!-- /snippet -->

`DU`, stages 1 and 3. Here the decision was to keep the edited file, and `git add` 🟢 records that. Back on `main`, the opposite decision: the deletion wins, and `git rm` records it.

<!-- snippet: ch08/conflict-modify-delete/05-resolve-delete -->
```text
# Back on main, same conflict as in the first snippet. Decision: the deletion wins.
$ git rm scripts/legacy_eval.sh
rm 'scripts/legacy_eval.sh'
$ git status --short
D  scripts/legacy_eval.sh
$ git merge --continue
[main 7e2950a] Merge branch 'cleanup/remove-legacy'
$ git ls-files
config/eval.yaml
evalkit/metrics.py
prompts/judge.txt
```
<!-- /snippet -->

The textbook's sentence for this type: the question is not "which file wins" but "why was it deleted, and does the edit need a new home?"

**[ANIMATION]** graph: 6ae3c51-e5b08ff main; 6ae3c51-727adba refactor/scoring-module; HEAD=main; note:e5b08ff:an_edit; note:727adba:a_rename title=An_edit_on_one_side,_a_rename_on_the_other

**Renames.** `labs/run ch08/conflict-rename`. First the good case. You edited `metrics.py` on `main`, and the refactoring branch renamed it to `scoring.py`. Predict: conflict or not? Say it out loud.

**[PAUSE]**

<!-- snippet: ch08/conflict-rename/01-rename-edit -->
```text
$ git log --oneline --graph --all
* e5b08ff Strip whitespace before comparing
| * 727adba Rename the metrics module to scoring
|/  
* 6ae3c51 Add eval config, judge prompt and metrics
$ git merge refactor/scoring-module
Merge made by the 'ort' strategy.
 evalkit/{metrics.py => scoring.py} | 0
 1 file changed, 0 insertions(+), 0 deletions(-)
 rename evalkit/{metrics.py => scoring.py} (100%)
$ git ls-files evalkit
evalkit/scoring.py
$ head -2 evalkit/scoring.py
def exact_match(pred, gold):
    return float(pred.strip() == gold.strip())
```
<!-- /snippet -->

No conflict. The summary says rename, 100 percent, and the `head` at the end shows your `strip()` edit inside `scoring.py`. Rename detection carried the edit across.

Two different renames of the same file do conflict.

<!-- snippet: ch08/conflict-rename/02-rename-rename -->
```text
$ git merge refactor/scorers
CONFLICT (rename/rename): evalkit/metrics.py renamed to evalkit/scoring.py in HEAD and to evalkit/scorers.py in refactor/scorers.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
DD evalkit/metrics.py
UA evalkit/scorers.py
AU evalkit/scoring.py
$ git ls-files -u
100644 9bbcd7ae8147833209c2dbce940d2fd9d681c8ac 1	evalkit/metrics.py
100644 9bbcd7ae8147833209c2dbce940d2fd9d681c8ac 3	evalkit/scorers.py
100644 9bbcd7ae8147833209c2dbce940d2fd9d681c8ac 2	evalkit/scoring.py
$ ls evalkit
scorers.py
scoring.py
```
<!-- /snippet -->

Three paths, three letter pairs: `DD` on the old name, `UA` on their name, `AU` on ours, and one stage per path. All three blobs have the same ID, because nobody changed the content. All three paths need an answer.

Try it now. Thirty seconds, on paper. The decision is that the module is called scoring. Write the three commands that answer all three paths, then say them out loud.

**[PAUSE]**

<!-- snippet: ch08/conflict-rename/03-rename-rename-resolve -->
```text
# Decision: the module is called scoring. All three paths need an answer.
$ git add evalkit/scoring.py
$ git rm evalkit/scorers.py
rm 'evalkit/scorers.py'
$ git rm evalkit/metrics.py
rm 'evalkit/metrics.py'
$ git status --short
$ git merge --continue
[main 02943f6] Merge branch 'refactor/scorers'
$ git ls-files evalkit
evalkit/scoring.py
```
<!-- /snippet -->

The answer: `git add` the name you keep, `git rm` the other two. If you wrote only one, you're not alone: that slip is on today's list of mistakes.

A rename against a deletion is reported under the new name.

<!-- snippet: ch08/conflict-rename/04-rename-delete -->
```text
$ git merge cleanup/drop-metrics
CONFLICT (rename/delete): evalkit/metrics.py renamed to evalkit/scoring.py in HEAD, but deleted in cleanup/drop-metrics.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
UD evalkit/scoring.py
$ git ls-files -u
100644 9bbcd7ae8147833209c2dbce940d2fd9d681c8ac 1	evalkit/scoring.py
100644 9bbcd7ae8147833209c2dbce940d2fd9d681c8ac 2	evalkit/scoring.py
```
<!-- /snippet -->

Now the hook. Ravi moved `metrics.py` to `scoring.py` and rewrote most of it in the same commit.

```bash
git diff --summary main...refactor/score-objects
git diff --summary --find-renames=30% main...refactor/score-objects
git merge refactor/score-objects
```

Predict what the first `diff --summary` reports, and what the merge will call the conflict. Say it out loud.

**[PAUSE]**

<!-- snippet: ch08/conflict-rename/05-below-threshold -->
```text
$ git diff --summary main...refactor/score-objects
 delete mode 100644 evalkit/metrics.py
 create mode 100644 evalkit/scoring.py
$ git diff --summary --find-renames=30% main...refactor/score-objects
 rename evalkit/{metrics.py => scoring.py} (39%)
$ git merge refactor/score-objects
CONFLICT (modify/delete): evalkit/metrics.py deleted in refactor/score-objects and modified in HEAD.  Version HEAD of evalkit/metrics.py left in tree.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
UD evalkit/metrics.py
A  evalkit/scoring.py
```
<!-- /snippet -->

With the default threshold: a delete and a create. With a threshold of 30 percent: a rename at 39 percent. There's the number that explains Ravi's answer. Only 39 percent of the content survived, so the merge sees a deletion and an addition, and reports `modify/delete`. He moved the file, Git saw a deletion, and both are right. Look at the last status line: `scoring.py` is staged, `A`, without your edit. If you ran `git rm` on the old path now, your edit would be gone and the merge would look finished.

**[DIAGRAM]** Show the root-cause box here.

The fix is to abort and tell the merge to use a lower threshold. `git merge -X find-renames=30%` 🟡 CAUTION, as every merge.

<!-- snippet: ch08/conflict-rename/06-find-renames -->
```text
$ git merge --abort
$ git merge -X find-renames=30% refactor/score-objects
Auto-merging evalkit/scoring.py
CONFLICT (content): Merge conflict in evalkit/scoring.py
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
D  evalkit/metrics.py
UU evalkit/scoring.py
$ grep -n -B1 -A5 '<<<<<<<' evalkit/scoring.py
11-def exact_match(pred, gold):
12:<<<<<<< HEAD:evalkit/metrics.py
13-    return float(pred.strip() == gold.strip())
14-=======
15-    return Score("exact_match", float(pred == gold))
16->>>>>>> refactor/score-objects:evalkit/scoring.py
17-
```
<!-- /snippet -->

The same merge is now a content conflict inside the new file, which is the conflict you can reason about. Look at the labels: `HEAD:evalkit/metrics.py` against `refactor/score-objects:evalkit/scoring.py`. They include paths, because the two sides know the file under different names.

**Binary.** `labs/run ch08/conflict-binary`.

<!-- snippet: ch08/conflict-binary/01-merge -->
```text
$ git merge feature/new-palette
warning: Cannot merge binary files: reports/confusion.png (HEAD vs. feature/new-palette)
Auto-merging reports/confusion.png
CONFLICT (content): Merge conflict in reports/confusion.png
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
UU reports/confusion.png
$ git ls-files -u
100644 ba14cea3b6767bd483472d2b9ba04134aef2afae 1	reports/confusion.png
100644 32a12ecade27b0c495b09a683cd0c12510e81468 2	reports/confusion.png
100644 c4a999a147a8710d34a4971df06840aaca348ba5 3	reports/confusion.png
$ git diff
diff --cc reports/confusion.png
index 32a12ec,c4a999a..0000000
Binary files differ
```
<!-- /snippet -->

A warning that binary files cannot be merged, then `CONFLICT (content)`, `UU`, and three stages. `git diff` says only "Binary files differ". Quick quiz. Which version is in the working tree? A, the base. B, ours. C, theirs. Your answer?

**[PAUSE]**

<!-- snippet: ch08/conflict-binary/02-which-version -->
```text
# The working tree file is our version (stage 2), byte for byte:
$ git hash-object reports/confusion.png
32a12ecade27b0c495b09a683cd0c12510e81468
```
<!-- /snippet -->

It's B. The hash equals the stage 2 entry, `32a12ec`, so it's our version, byte for byte.

<!-- snippet: ch08/conflict-binary/03-resolve -->
```text
# Decision: regenerate later; for now take their file.
$ git restore --theirs reports/confusion.png
$ git hash-object reports/confusion.png
c4a999a147a8710d34a4971df06840aaca348ba5
$ git status --short
UU reports/confusion.png
$ git add reports/confusion.png
$ git status --short
M  reports/confusion.png
$ git merge --continue
[main 4d7fbd3] Merge branch 'feature/new-palette'
```
<!-- /snippet -->

`git restore --theirs` writes stage 3, the hash confirms it, and the path stays `UU` until `git add`. For a generated artifact such as this confusion-matrix image, the honest resolution is to regenerate it from the merged sources.

**File against directory.** `labs/run ch08/conflict-file-directory`. One branch added a file named `docs`, the other a directory named `docs`.

<!-- snippet: ch08/conflict-file-directory/01-merge -->
```text
$ git merge feature/docs-directory
CONFLICT (file/directory): directory in the way of docs from HEAD; moving it to docs~HEAD instead.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
D  docs
A  docs/calibration.md
AU docs~HEAD
$ git ls-files -s docs docs~HEAD
100644 37cc29f51e7d512294b921cadd0f36e408ede85a 0	docs/calibration.md
100644 7ef0c38ff113fe6b29f348c4cce89653ba08aac7 2	docs~HEAD
```
<!-- /snippet -->

Both cannot exist, so Git moved the file aside to `docs~HEAD`, a name that says where it came from.

**Directory rename.** `labs/run ch08/conflict-directory-rename`. You moved the package under `src/`. Asha added a new file in the old directory.

<!-- snippet: ch08/conflict-directory-rename/01-merge -->
```text
$ git diff --name-status feature/cache...main
R100	evalkit/__init__.py	src/evalkit/__init__.py
R100	evalkit/metrics.py	src/evalkit/metrics.py
R100	evalkit/report.py	src/evalkit/report.py
$ git diff --name-status main...feature/cache
A	evalkit/cache.py
$ git merge feature/cache
CONFLICT (file location): evalkit/cache.py added in feature/cache inside a directory that was renamed in HEAD, suggesting it should perhaps be moved to src/evalkit/cache.py.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status --short
UA src/evalkit/cache.py
$ git ls-files -u
100644 7f040298ad3ac9af50f69563114d5f3f5fff3576 3	src/evalkit/cache.py
$ ls src/evalkit
__init__.py
cache.py
metrics.py
report.py
```
<!-- /snippet -->

`CONFLICT (file location)`. Git noticed that the directory was renamed and suggests where the new file should perhaps go. No markers, one stage, and the file is already at the suggested path. Accepting is one command.

<!-- snippet: ch08/conflict-directory-rename/02-resolve -->
```text
# Git has already written the file where it suggests. Accepting the suggestion is one command:
$ git add src/evalkit/cache.py
$ git status --short
A  src/evalkit/cache.py
$ git merge --continue
[main d1b5f4e] Merge branch 'feature/cache'
$ git ls-files src
src/evalkit/__init__.py
src/evalkit/cache.py
src/evalkit/metrics.py
src/evalkit/report.py
```
<!-- /snippet -->

`merge.directoryRenames` controls this. Its default is `conflict`. The other two values act without asking.

<!-- snippet: ch08/conflict-directory-rename/03-config -->
```text
# The same merge with merge.directoryRenames=true does not stop:
$ git -c merge.directoryRenames=true merge feature/cache
Path updated: evalkit/cache.py added in feature/cache inside a directory that was renamed in HEAD; moving it to src/evalkit/cache.py.
Merge made by the 'ort' strategy.
 src/evalkit/cache.py | 5 +++++
 1 file changed, 5 insertions(+)
 create mode 100644 src/evalkit/cache.py
# With merge.directoryRenames=false the new file stays in the old directory, without a word:
$ git -c merge.directoryRenames=false merge feature/cache
Merge made by the 'ort' strategy.
 evalkit/cache.py | 5 +++++
 1 file changed, 5 insertions(+)
 create mode 100644 evalkit/cache.py
$ git ls-files evalkit src
evalkit/cache.py
src/evalkit/__init__.py
src/evalkit/metrics.py
src/evalkit/report.py
```
<!-- /snippet -->

With `true` Git moves the file and tells you. With `false` the merge is clean and wrong: `evalkit/cache.py` sits in a directory that no longer contains the package. The default costs one `git add`.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Each mistake with its root cause.

1. **Looking for markers in a modify/delete conflict and concluding that nothing is wrong.** Root cause: the type is decided on paths, not on lines, so the working tree holds the modified version without markers and the conflict exists only in the index.
2. **Resolving a below-threshold rename with `git rm` on the old path.** Root cause: rename detection failed under 50% similarity, so the new file was staged without your edit and the `git rm` discards it.
3. **Using `git restore --theirs` on a path they deleted and expecting an error.** Root cause: there is no stage 3, and `git restore` treats "their version" as "no file", while `git checkout --theirs` refuses.
4. **Answering only one path of a rename/rename conflict.** Root cause: the conflict spans three paths with one stage each, and each needs a `git add` or a `git rm`.
5. **Setting `merge.directoryRenames=false` to stop the questions.** Root cause: the merge then leaves new files in the old directory without a word, which is clean for Git and wrong for the project.

## PRODUCTION EXAMPLE

Now, out of the lab. A model-evaluation team restructures its Python package: `evalkit/` moves under `src/`, the metrics module is renamed, and scores become objects. The refactoring branch lives for two weeks. Meanwhile four feature branches edit the old module and one adds a cache file to the old directory.

**[ANIMATION]** cards: question=Merge_day,_one_afternoon cards=a_file-location_conflict|a_rename_that_carried_edits_across|one_modify/delete:moved_and_rewritten_in_a_single_commit marks=3:ring at_1=20 at_2=32 at_3=45

On merge day the team sees, in one afternoon, a file-location conflict, a rename that carried edits across cleanly, and one `modify/delete` on the module that was moved and rewritten in a single commit. The third one costs an hour, because the first reaction was to ask who deleted the module.

**[ANIMATION]** step: box.7

The textbook's advice for exactly this situation: refactoring branches are where these types appear together. Announce large moves, land them quickly, and merge them into open feature branches the same day. And from the root-cause box: land the move as its own change and merge it into every open branch before the rewrite starts.

## PRACTICE EXERCISE

Your turn. Do Lab 6.3, "Rename against edit", in [`lab-manual/m06-merge.md`](../../lab-manual/m06-merge.md).

Predict first, in writing:

- Will the merge stop? What decides it?
- If it does not stop, in which file will your edit be after the merge?
- What would `git diff --summary` between the two branch tips print, and which number in it would have to change for the outcome to be different?

Then run the lab by hand. The challenge is Lab 6.4, "Modify against delete", in the same file. For that one, write down which stages you expect before you run `git ls-files -u`.

## INTERVIEW QUESTION

**[ON SCREEN]** The question.

Q124: "State the three-way rule for a single path as a table of base, ours and theirs. Which rows never read file content?"

**[PAUSE]**

Answer out loud first. A strong answer draws the table from memory, with a row for each combination of unchanged, changed and absent, and gives the result for each row. It then separates the rows that are decided by comparing object IDs or by presence and absence from the row that needs a line-by-line merge. It connects that distinction to today's video: the conflict types without markers are the rows that never opened the file. If you can also say why that makes merges of large repositories fast, say it.

## RECAP

Let's land this. You should now be able to say:

**[ANIMATION]** step: stages.5

The word in parentheses after `CONFLICT` names the type, and only some types write markers. For a conflict without markers, the stages in the index are the conflict: a missing stage 1 means both sides added the path, and a missing stage 2 or 3 means one side deleted it. Git infers renames from content with a 50 percent threshold, so a move plus a rewrite in one commit can turn into a `modify/delete`, and `-X find-renames` with a lower value turns it back into a content conflict. A binary conflict leaves our version in the working tree and is resolved by choosing a stage or regenerating the file. `merge.directoryRenames` defaults to `conflict`, and that default costs one `git add`.

## HOMEWORK

Read section 8.11 of [Chapter 8](../../textbook/ch08-merge.md).

Copy the table of conflict types into your own notes: type, status letters, stages present, markers yes or no, resolving command. Keep it. Part 9 uses it.

Today a conflict without markers stopped being a dead end: you read the type, you read the stages, and then you decide. Do Lab 6.3 while this is fresh. Next time: controlling the result of a merge. Until then, look at the state first and type second. See you in the next one.
