# Solutions to the exercises of Modules 11 to 15

> **Baseline.** Git 2.55.0 and git-lfs 3.7.1 on macOS. Every transcript below is real output of a replay script in `labs/ex2/`: `answers-mNN.sh` for exercises 1 to 8 of a module, `solve-<name>.sh` for each Level 4 and Level 5 exercise. `labs/run ex2/<script name>` replays one of them on your machine. `$LAB` stands for the lab root.

The questions are in [exercises/m11-m15-investigation-recovery.md](../exercises/m11-m15-investigation-recovery.md). Each solution has the same five parts: the solution, the reasoning, the common mistakes, the expert approach, and the textbook sections that teach it.

Two notes on reading the transcripts. The replays run in sandboxes named `ex2/answers-mNN` and `ex2/solve-<name>`, yours are named `exercises/<name>`; only printed paths differ. Commits that a replay creates carry the lab clock, yours carry the real one, so their IDs differ from yours; every commit that a generator created has the same ID in both.

---

## Module 11: History investigation

The repository of exercises 11.1 to 11.8, for reference:

<!-- snippet: ex2/answers-m11/11-0-graph -->
```text
$ git log --graph --oneline --all
* 3859100 Add a command-line entry point
* 8133039 Document chunk sizes in the README
*   5e8101a Merge branch 'fix/clean-tabs'
|\  
| * 6f652d0 Collapse tabs in the cleaner
* | 06192d8 Move window into its own module
* | 34c0625 Fix off-by-one in paragraph splitter
| | * 6cf0f67 Fix off-by-one in paragraph splitter
| | * fab8339 Document the Markdown splitter
| | * 679ef01 Add Markdown heading splitter
| |/  
|/|   
* | a558126 Drop the legacy YAML configuration
* | 22d9edc Rewrite the cleaner with one regular expression
|/  
* abcfc8e Simplify the window loop
* de59336 Reduce overlap to 32
* e639777 Sort the configuration constants
*   1e21328 Merge branch 'feat/sentence-split'
|\  
| * 246aa3e Handle abbreviations in the sentence splitter
| * 42dacf5 Add sentence splitter
* | 4d992b7 Keep the tail in the last window
|/  
* 5ffd993 Raise chunk size to 512
* 6f9debb Add whitespace cleaner
* 6acbb71 Add sliding window over tokens
* b5630d4 Add chunk configuration
* d0fee8f Add paragraph splitter
* 7c7a97e Add project skeleton
```
<!-- /snippet -->

### Exercise 11.1

**Solution.**

<!-- snippet: ex2/answers-m11/11-1-filters -->
```text
$ git log --oneline --author=Asha
8133039 Document chunk sizes in the README
06192d8 Move window into its own module
6f652d0 Collapse tabs in the cleaner
e639777 Sort the configuration constants
5ffd993 Raise chunk size to 512
b5630d4 Add chunk configuration
$ git log --oneline -- docsplit/config.py
de59336 Reduce overlap to 32
e639777 Sort the configuration constants
5ffd993 Raise chunk size to 512
b5630d4 Add chunk configuration
$ git log --oneline --merges
5e8101a Merge branch 'fix/clean-tabs'
1e21328 Merge branch 'feat/sentence-split'
$ git log --format='%h %ad %an: %s' --date=format:'%a %H:%M' --since='2026-09-09 00:00' --until='2026-09-09 23:59'
a558126 Wed 08:26 Lab User: Drop the legacy YAML configuration
22d9edc Wed 08:24 Lab User: Rewrite the cleaner with one regular expression
6f652d0 Wed 08:22 Asha Rao: Collapse tabs in the cleaner
abcfc8e Wed 08:20 Ravi Menon: Simplify the window loop
de59336 Wed 08:19 Ravi Menon: Reduce overlap to 32
```
<!-- /snippet -->

1. Asha wrote six commits. Three of them touch `docsplit/config.py`. Filters combine with "and", so one command answers the second part:

<!-- snippet: ex2/answers-m11/11-1-dates -->
```text
$ git log --format='%h author %ad | committer %cd | %an, %cn' --date=format:'%a %H:%M' -1 34c0625
34c0625 author Wed 08:30 | committer Thu 07:32 | Ravi Menon, Lab User
$ git log --oneline --author=Asha -- docsplit/config.py | wc -l
       3
```
<!-- /snippet -->

2. `6f652d0`, "Collapse tabs in the cleaner". It was committed on the branch `fix/clean-tabs` and became reachable from `main` through the merge `5e8101a`. `git log` walks all parents of a merge unless `--first-parent` tells it not to.
3. The committer date. `34c0625` on `main` is a cherry-pick: Ravi authored the change on Wednesday at 08:30 and you committed the copy on Thursday at 07:32, which the first command of the second transcript shows. That is why Wednesday's list does not contain it, although `%ad` would print a Wednesday date for it.
4. A date without a time takes the current time of day, so `--since=2026-09-09` would cut the day at whatever the clock reads when you run the command.

**Reasoning.** `git log` works in three steps: walk the graph from the starting points, filter the visited commits, format what is left. `--author`, `--merges`, the dates and the path are all filters of the second step. The path filter compares each commit's version of the path with its parent's.

**Common mistakes.** Reading `--author=Asha` as "commits on Asha's branch": it is a pattern matched against the author header. Assuming `--since` looks at the date that the default log output prints: the default output shows the author date, the filter tests the committer date. Counting by eye instead of piping into `wc -l` or using `git rev-list --count`.

**Expert approach.** State the question as walk, filter, format before typing: "from `main`, only Asha, only this path, count". When a date matters, print both dates with `%ad` and `%cd` and give an explicit time of day.

**Reference.** Chapter 14A, section 14A.9 (the three steps, the filters, both date traps) and section 14A.15 (formats). Author and committer dates: Chapter 6, section 6.5.

### Exercise 11.2

**Solution.**

<!-- snippet: ex2/answers-m11/11-2-pickaxe -->
```text
$ git log --oneline -S'OVERLAP'
06192d8 Move window into its own module
6acbb71 Add sliding window over tokens
b5630d4 Add chunk configuration
$ git log --oneline -G'OVERLAP'
06192d8 Move window into its own module
de59336 Reduce overlap to 32
e639777 Sort the configuration constants
6acbb71 Add sliding window over tokens
b5630d4 Add chunk configuration
```
<!-- /snippet -->

1. `-S<string>` lists a commit when the number of occurrences of the string in a file differs between the commit and its parent. `-G<regex>` lists a commit when an added or removed line of its diff matches the pattern.
2. Only `-G` lists `e639777` and `de59336`. In `e639777` the line with `OVERLAP` moved: it is removed in one place and added in another, so the diff has matching lines, and the count stays at one.

<!-- snippet: ex2/answers-m11/11-2-why -->
```text
$ git show --format=%s e639777 -- docsplit/config.py
Sort the configuration constants

diff --git a/docsplit/config.py b/docsplit/config.py
index 5e6d75f..aa8eca5 100644
--- a/docsplit/config.py
+++ b/docsplit/config.py
@@ -1,5 +1,5 @@
 """Chunking defaults."""
 
-CHUNK_SIZE = 512
-OVERLAP = 40
 MIN_CHARS = 20
+OVERLAP = 40
+CHUNK_SIZE = 512
$ git grep -c OVERLAP e639777^ e639777 -- docsplit/config.py
e639777^:docsplit/config.py:1
e639777:docsplit/config.py:1
```
<!-- /snippet -->

   `de59336` changed `OVERLAP = 40` to `OVERLAP = 32`: one line removed, one added, one occurrence before and after.
3. `-G`, with a pattern that pins the assignment, for example `git log -G'^OVERLAP = ' -- docsplit/config.py`. `-S'OVERLAP'` cannot see a change of value, because the name occurs once before and once after.
4. `06192d8`, "Move window into its own module". The count is taken per file. The function left `docsplit/split.py` (the count there dropped) and arrived in `docsplit/window.py` (the count there rose), so both files changed their count although the repository as a whole did not.

**Reasoning.** `-S` answers "when did this text appear or disappear", `-G` answers "which commits touched a line like this". A moved or edited line keeps the count and still appears in the diff.

**Common mistakes.** Using `-S` to find who changed a value. Forgetting that `-S` takes a literal string unless `--pickaxe-regex` is given, while `-G` always takes a regular expression. Reading the first hit as the origin: both options list every match, newest first.

**Expert approach.** Start with `-S` and the most specific text you have (it is the faster test and gives the shorter list), add `-p` or `--stat` to see the hits, and switch to `-G` when the question is about edits to a line and not about its existence.

**Reference.** Chapter 14A, section 14A.11.

### Exercise 11.3

**Solution.**

<!-- snippet: ex2/answers-m11/11-3-blame -->
```text
$ git blame -L 3,5 docsplit/config.py
b5630d48 (Asha Rao   2026-09-07 10:05:00 +0530 3) MIN_CHARS = 20
de59336b (Ravi Menon 2026-09-09 08:19:00 +0530 4) OVERLAP = 32
e639777b (Asha Rao   2026-09-08 09:17:00 +0530 5) CHUNK_SIZE = 512
$ git show --stat --format='%h %an: %s' e639777b
e639777 Asha Rao: Sort the configuration constants

 docsplit/config.py | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
$ git blame -L '/CHUNK_SIZE/,+1' e639777b^ -- docsplit/config.py
5ffd9934 (Asha Rao 2026-09-08 09:09:00 +0530 3) CHUNK_SIZE = 512
```
<!-- /snippet -->

1. It names the last commit that changed the text of that line: `e639777`, "Sort the configuration constants". It does not say that this commit chose the value. Here the commit moved the line and changed nothing in it.
2. Asha, in `5ffd993`, "Raise chunk size to 512" (compare the ID with the graph above). Two commands after the first blame: `git show` to see what the blamed commit did, and a second blame that starts at its parent.
3. `<commit>^` is the first parent of the commit: the state immediately before it. `-L '/CHUNK_SIZE/,+1'` selects one line, starting at the first line that matches the regular expression. A line number would be wrong here, because the line was at another position before the sort.
4. `--ignore-rev e639777` blames the lines of that commit on the commit that changed them before. It needs a commit ID, which is why you have to run the plain blame first, or keep a list in a file for `--ignore-revs-file`.

**Reasoning.** Blame is a function of the current text and the diffs that produced it. Any commit that rewrites a line, including one that moves or reformats it, becomes the answer for that line.

**Common mistakes.** Treating the blamed author as the person who made the decision. Re-running blame with the same line numbers on an older commit, where the numbers mean other lines. Using `git blame <commit>` without `^`, which names the same commit again.

**Expert approach.** Blame, then `git show` the named commit and ask "did this commit decide the content of the line?". If not, step to its parent with a regular-expression range, or use `git log -L` to see the whole history of the line at once.

**Reference.** Chapter 14A, section 14A.16 (what blame tells you and what it does not) and section 14A.17 (`--ignore-rev`).

### Exercise 11.4

**Solution.**

<!-- snippet: ex2/answers-m11/11-4-ranges -->
```text
$ git log --oneline main..feat/markdown
6cf0f67 Fix off-by-one in paragraph splitter
fab8339 Document the Markdown splitter
679ef01 Add Markdown heading splitter
$ git log --oneline feat/markdown..main | wc -l
       6
$ git rev-list --left-right --count main...feat/markdown
6	3
$ git log --oneline --cherry-pick --right-only main...feat/markdown
fab8339 Document the Markdown splitter
679ef01 Add Markdown heading splitter
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m11/11-4-diff -->
```text
$ git diff --stat main...feat/markdown
 README.md            |  2 ++
 docsplit/markdown.py | 13 +++++++++++++
 docsplit/split.py    |  2 +-
 3 files changed, 16 insertions(+), 1 deletion(-)
$ git diff --stat main..feat/markdown
 README.md            |  2 +-
 docsplit/__main__.py |  9 ---------
 docsplit/markdown.py | 13 +++++++++++++
 docsplit/split.py    |  7 +++++++
 docsplit/window.py   |  8 --------
 5 files changed, 21 insertions(+), 18 deletions(-)
```
<!-- /snippet -->

1. `main..feat/markdown` selects by reachability: three commits are reachable from the branch and not from `main`. `--cherry-pick` then drops commits whose change exists on the other side as well. `6cf0f67` on the branch and `34c0625` on `main` are two commits with the same patch, so only two commits are left.
2. A pull request shows the three-dot form: the difference between the merge base and the tip of the branch, three files, which is what the branch did. The two-dot form compares the two tips. It lists `docsplit/__main__.py` and `docsplit/window.py` as deletions because `main` added them after the branch point and the branch does not have them: differences that are the work of `main`, shown as if the branch had undone them.

**Reasoning.** For `git log`, `A..B` is "reachable from B, not from A" and `A...B` is the symmetric difference; `--left-right --count` prints the size of both halves, six and three. For `git diff` there are no sets: `A..B` is `git diff A B`, and `A...B` is `git diff $(git merge-base A B) B`.

**Common mistakes.** Carrying the meaning of the dots from `log` to `diff`. Expecting `--cherry-pick` to compare commit IDs or subjects: it compares patch IDs, so a cherry-pick that needed a conflict resolution is not recognized. Forgetting that the fix shows up in the three-dot diff of the branch although `main` already has it: the diff is against the merge base, which does not.

**Expert approach.** Before a review or a merge: `git rev-list --left-right --count main...topic` for the shape, `git log --oneline --cherry-mark --left-right main...topic` for the commits, `git diff main...topic` for the change.

**Reference.** Chapter 14A, section 14A.2 (`git diff` endpoints), section 14A.8 (ranges) and section 14A.14 (`--left-right`, `--cherry-pick`). Patch IDs: Chapter 10, section 10.10.

### Exercise 11.5

**Solution.**

<!-- snippet: ex2/answers-m11/11-5-deleted -->
```text
$ git log --diff-filter=D --oneline -- configs/legacy.yaml
a558126 Drop the legacy YAML configuration
$ git restore --source=a558126^ --staged --worktree -- configs/legacy.yaml
$ git status -s
A  configs/legacy.yaml
$ cat configs/legacy.yaml
# Read by the old batch job only.
chunk_size: 400
overlap: 40
$ git log -1 --oneline
3859100 Add a command-line entry point
```
<!-- /snippet -->

`--diff-filter=D` keeps only commits that delete the path. The file's last content is in the parent of that commit, and `git restore --source=<commit>^ --staged --worktree` copies it into the index and the working tree. `HEAD` did not move: the last command still shows the tip of `main`.

**Reasoning.** A deleted file has not left the repository. Every commit before the deletion still has it in its tree. Finding it is a log query, and getting it back is a copy out of a commit, with no need to move `HEAD`.

**Common mistakes.** `git log -- configs/legacy.yaml` without `--diff-filter` also works, and shows the deleting commit first, but it does not tell you which of the listed commits deleted the file. Restoring from the deleting commit itself, where the file no longer exists: the source is its parent. `git checkout <commit>^` to "go and get the file", which detaches `HEAD` and replaces the whole working tree. Leaving out `--staged`, after which the file is untracked and a later `git commit -a` does not include it.

**Expert approach.** `git log --diff-filter=D --name-only -1 -- <path>` to get the commit, `git show <commit>^:<path>` to read the content first, then the restore. If you do not know the exact path, use a glob: `git log --diff-filter=D --name-only -- '*legacy*'`.

**Reference.** Chapter 14A, section 14A.13 (finding a deleted file) and section 14A.3 (`--diff-filter`). `git restore --source`: Chapter 11, section 11.3.

### Exercise 11.6

**Solution.**

<!-- snippet: ex2/answers-m11/11-6-notes -->
```text
$ git log --no-merges --reverse --format='- %s (%an)' v0.2.0..v0.3.0
- Reduce overlap to 32 (Ravi Menon)
- Simplify the window loop (Ravi Menon)
- Collapse tabs in the cleaner (Asha Rao)
- Rewrite the cleaner with one regular expression (Lab User)
- Drop the legacy YAML configuration (Lab User)
- Fix off-by-one in paragraph splitter (Ravi Menon)
- Move window into its own module (Asha Rao)
- Document chunk sizes in the README (Asha Rao)
$ git shortlog -sn --no-merges v0.2.0..v0.3.0
     3	Asha Rao
     3	Ravi Menon
     2	Lab User
$ git log --first-parent --oneline v0.2.0..v0.3.0
8133039 Document chunk sizes in the README
5e8101a Merge branch 'fix/clean-tabs'
06192d8 Move window into its own module
34c0625 Fix off-by-one in paragraph splitter
a558126 Drop the legacy YAML configuration
22d9edc Rewrite the cleaner with one regular expression
abcfc8e Simplify the window loop
de59336 Reduce overlap to 32
```
<!-- /snippet -->

List 1 has eight commits. List 3 has eight lines too, but one of them is the merge `5e8101a`, so it shows seven non-merge commits. The difference is `6f652d0`, "Collapse tabs in the cleaner": it reached `main` through that merge and is not on the first-parent line.

**Reasoning.** `v0.2.0..v0.3.0` selects everything that the newer release has and the older one lacks. `--no-merges` removes commits with more than one parent from the output, without changing the walk. `--first-parent` changes the walk: it does not enter merged branches. The two views answer "which changes are in the release" and "what landed on `main`, in which order".

**Common mistakes.** Running `git shortlog` without a revision inside a script: it then waits for input on standard input. Using `--first-parent` to count changes: it hides the commits inside each merge. Taking `Lab User` in the shortlog for the committer: `shortlog` groups by author unless `-c` is given.

**Expert approach.** For release notes in a repository that merges pull requests, the first-parent list is usually the right level: one line per landed change. Add `--cherry-pick --right-only` against the previous release branch when fixes were backported, so that they are not announced twice.

**Reference.** Chapter 14A, section 14A.9 (`--first-parent`, `--no-merges`) and section 14A.15 (pretty formats, `git shortlog`).

### Exercise 11.7

**Solution.** Plain blame gives the misleading picture, and `-C` corrects it:

<!-- snippet: ex2/answers-m11/11-7-blame -->
```text
$ git blame -s docsplit/window.py
06192d80 1) """Sliding windows over a token list."""
06192d80 2) 
06192d80 3) from docsplit.config import CHUNK_SIZE, OVERLAP
06192d80 4) 
06192d80 5) 
06192d80 6) def window(tokens, size=CHUNK_SIZE, overlap=OVERLAP):
06192d80 7)     step = size - overlap
06192d80 8)     return [tokens[start:start + size] for start in range(0, len(tokens) - size + 1, step)]
$ git blame -s -C docsplit/window.py
06192d80 docsplit/window.py 1) """Sliding windows over a token list."""
d0fee8f6 docsplit/split.py  2) 
6acbb71c docsplit/split.py  3) from docsplit.config import CHUNK_SIZE, OVERLAP
6acbb71c docsplit/split.py  4) 
d0fee8f6 docsplit/split.py  5) 
6acbb71c docsplit/split.py  6) def window(tokens, size=CHUNK_SIZE, overlap=OVERLAP):
6acbb71c docsplit/split.py  7)     step = size - overlap
abcfc8eb docsplit/split.py  8)     return [tokens[start:start + size] for start in range(0, len(tokens) - size + 1, step)]
```
<!-- /snippet -->

With `-C`, blame looks for the origin of lines in other files that the same commit changed. Seven of the eight lines came from `docsplit/split.py`, and the one line that computes the windows is from `abcfc8e`:

<!-- snippet: ex2/answers-m11/11-7-origin -->
```text
$ git show abcfc8eb
commit abcfc8eb34b535c585ee6a303ad6e21de26fcce4
Author: Ravi Menon <ravi@example.com>
Date:   Wed Sep 9 08:20:00 2026 +0530

    Simplify the window loop

diff --git a/docsplit/split.py b/docsplit/split.py
index bbc4240..3dd964e 100644
--- a/docsplit/split.py
+++ b/docsplit/split.py
@@ -10,9 +10,4 @@ def split_paragraphs(text):
 
 def window(tokens, size=CHUNK_SIZE, overlap=OVERLAP):
     step = size - overlap
-    chunks = []
-    for start in range(0, len(tokens), step):
-        chunks.append(tokens[start:start + size])
-        if start + size >= len(tokens):
-            break
-    return chunks
+    return [tokens[start:start + size] for start in range(0, len(tokens) - size + 1, step)]
```
<!-- /snippet -->

Ravi's "Simplify the window loop" replaced a loop that kept the tail with a comprehension that stops at `len(tokens) - size + 1`. The line history confirms it from the other direction: in the new file the function has one commit, the move; continued in the old file from the parent of the move, it has three.

<!-- snippet: ex2/answers-m11/11-7-linelog -->
```text
$ git log --oneline --no-patch -L :window:docsplit/window.py
06192d8 Move window into its own module
$ git log --oneline --no-patch -L :window:docsplit/split.py 06192d8^
abcfc8e Simplify the window loop
4d992b7 Keep the tail in the last window
6acbb71 Add sliding window over tokens
$ git log -1 --format='%h %an%n%n%B' 4d992b7
4d992b7 Lab User

Keep the tail in the last window

A document shorter than one window produced no chunk at all, and the last tokens of every longer document were dropped. The final window may now be shorter than size.
```
<!-- /snippet -->

The behavior that was lost came from `4d992b7`, "Keep the tail in the last window", whose message states the reason: short documents produced no chunk, and long ones lost their last tokens. Asha is right. `git show --stat 06192d8` and the `-C` blame both show that her commit moved the lines unchanged.

**Reasoning.** Git does not record moves. Blame and `git log -L` follow a file through its history, and a function that is cut out of one file and pasted into a new one starts a new history there unless you ask Git to look for the source (`-C`). The regression was committed before the move, so every tool that starts in the new file stops at the move unless it can cross it.

**Common mistakes.** Stopping at the first blame and assigning the bug to the person who moved the code. Running `git log -L :window:docsplit/window.py`, seeing one commit, and concluding that the function was never changed. Reaching for `git log --follow`, which follows renames of a whole file, not a function that moved between two files that both continue to exist.

**Expert approach.** When blame attributes a whole block to one commit, look at that commit's `--stat` first: a new file with as many added lines as another file lost is a move. Then `git blame -C` (a second `-C` extends the search, in the commit that creates the file, to files which that commit did not change), or the pickaxe on a distinctive line: `git log -S'len(tokens) - size + 1'` lists the commits where that text appeared and disappeared, in whichever file it lived.

**Reference.** Chapter 14A, section 14A.12 (`git log -L`), section 14A.18 (blame and moved code, `-C`) and section 14A.19 (the method: blame, show, pickaxe, bisect).

### Exercise 11.8

**Solution.**

<!-- snippet: ex2/answers-m11/11-8-simplified -->
```text
$ git log --oneline -- docsplit/clean.py
22d9edc Rewrite the cleaner with one regular expression
6f9debb Add whitespace cleaner
$ git log --oneline --author=Asha -- docsplit/clean.py
$ git log --oneline --full-history -- docsplit/clean.py
5e8101a Merge branch 'fix/clean-tabs'
22d9edc Rewrite the cleaner with one regular expression
6f652d0 Collapse tabs in the cleaner
6f9debb Add whitespace cleaner
$ git merge-base --is-ancestor 6f652d0 main; echo "exit status: $?"
exit status: 0
```
<!-- /snippet -->

Her commit `6f652d0` is an ancestor of `main` (exit status 0). No history was rewritten. The path-limited log leaves it out because of history simplification: with a path, `git log` shows commits whose version of the path differs from their parent's, and at a merge whose result for that path equals one parent it follows only that parent. The merge `5e8101a` has, for `docsplit/clean.py`, exactly the content of its first parent, so the side branch is pruned from the walk. `--full-history` switches the pruning off and shows her commit and the merge.

What happened to the change is in the merge:

<!-- snippet: ex2/answers-m11/11-8-merge -->
```text
$ git show --remerge-diff --format='%h %s' 5e8101a
5e8101a Merge branch 'fix/clean-tabs'

diff --git a/docsplit/clean.py b/docsplit/clean.py
remerge CONFLICT (content): Merge conflict in docsplit/clean.py
index 3aa5354..4cae717 100644
--- a/docsplit/clean.py
+++ b/docsplit/clean.py
@@ -6,11 +6,4 @@ _SPACES = re.compile(" +")
 
 
 def clean(text):
-<<<<<<< 06192d8 (Move window into its own module)
     return _SPACES.sub(" ", text).strip()
-=======
-    text = text.replace("\t", " ")
-    while "  " in text:
-        text = text.replace("  ", " ")
-    return text.strip()
->>>>>>> 6f652d0 (Collapse tabs in the cleaner)
```
<!-- /snippet -->

`--remerge-diff` repeats the merge and shows the difference between the mechanical result and what was committed. The two branches had conflicted in `clean()`, and the person who merged (you, according to the graph and `git log -1 5e8101a`) resolved the conflict by taking the version of `main` and dropping the tab handling. The regular expression `" +"` on `main` does not collapse tabs, so the fix is lost.

What should be done: a new commit on `main` that adds the tab handling to the rewritten cleaner, for example `re.compile(r"[ \t]+")`, with a message that refers to `6f652d0` and to the merge. Not a revert of the merge, and not a rewrite: the merge is public history and everything else in it is correct.

**Reasoning.** Three facts are independent and have to be established separately: the commit is in the history (reachability), the path-limited log hides it (a display rule), and its content is not in the final tree (a conflict resolution). Mixing them up produces "Git lost my commit".

**Common mistakes.** Concluding from a path-limited log that a commit does not exist. Looking at `git show <merge>` and seeing nothing for the file: the default combined diff shows only lines that differ from every parent, and a resolution that takes one side unchanged is invisible there. Blaming the tool: Git reported the conflict, and a person chose.

**Expert approach.** For "my change vanished": `git branch --contains <commit>` or `git merge-base --is-ancestor`, then `git log --full-history --oneline -- <path>` to find the merges on the way, then `git show --remerge-diff` on each. In review, treat a whole-file "ours" in a conflict as a decision that needs a sentence in the merge message.

**Reference.** Chapter 14A, section 14A.9 (path-limited log and `--full-history`). Chapter 8, section 8.16 (auditing a merge, what each diff of a merge is blind to) and section 8.19 (the symptom "a teammate's change vanished in a merge").

### Exercise 11.9

**Solution.** The check always exits with 0, and on some commits it cannot run. A test for bisect has to tell three cases apart:

<!-- snippet: ex2/solve-m11-judgekit/01-observe -->
```text
$ git status -sb
## main
$ git rev-list --count v1.0.0..v1.1.0
13
$ python3 -B check_agreement.py; echo "exit status: $?"
agreement 0.70
exit status: 0
$ git switch --detach -q v1.0.0 && python3 -B check_agreement.py; git switch -q main
agreement 0.90
```
<!-- /snippet -->

<!-- snippet: ex2/solve-m11-judgekit/02-script -->
```text
$ cat ../test-agreement.sh
#!/bin/sh
# good (0): agreement of at least 0.90; bad (1): lower; 125: the check cannot run on this commit
out=$(python3 -B check_agreement.py 2>/dev/null) || exit 125
case "$out" in
  "agreement 0.9"*|"agreement 1.0"*) exit 0 ;;
  "agreement "*)                     exit 1 ;;
  *)                                 exit 125 ;;
esac
```
<!-- /snippet -->

Thirteen commits, so about four steps. The run ends without a single answer:

<!-- snippet: ex2/solve-m11-judgekit/03-bisect -->
```text
$ git bisect start v1.1.0 v1.0.0
Bisecting: 6 revisions left to test after this (roughly 3 steps)
[6f17e851a76c283b14a6f6b32990483f95308f98] Treat 'partially correct' as a pass
$ git bisect run ../test-agreement.sh
running '../test-agreement.sh'
Bisecting: 5 revisions left to test after this (roughly 3 steps)
[0f15a4b3443008dc772e12e88fee209690cc7c2a] Add timeout option to the judge client
running '../test-agreement.sh'
Bisecting: 5 revisions left to test after this (roughly 3 steps)
[0d5726542e789bd3836b498f22354ddca45ae7b1] Add a prompt that carries the rubric
running '../test-agreement.sh'
Bisecting: 4 revisions left to test after this (roughly 2 steps)
[20d6e4843b4c96196ea4f1072619685b22a6d8d6] Accept lowercase verdicts
running '../test-agreement.sh'
Bisecting: 4 revisions left to test after this (roughly 2 steps)
[517dbd94fc21531508e5547fd4ed5f01f86e0e2e] Describe the golden set format
running '../test-agreement.sh'
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[d2d5498fa4c416cc45a4b48f9c3d989d83e49c6d] Move verdict parsing into judgekit/verdict.py
running '../test-agreement.sh'
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[259fb40881f35f446700e5ef26d4d4b0cca3a0f6] Fix import after the verdict module move
running '../test-agreement.sh'
Bisecting: 2 revisions left to test after this (roughly 2 steps)
[28a8db4d430e57a1fb7d1626f6f9365c54bff010] Add the grading prompt template
running '../test-agreement.sh'
There are only 'skip'ped commits left to test.
The first 'bad' commit could be any of:
20d6e4843b4c96196ea4f1072619685b22a6d8d6
6f17e851a76c283b14a6f6b32990483f95308f98
0f15a4b3443008dc772e12e88fee209690cc7c2a
d2d5498fa4c416cc45a4b48f9c3d989d83e49c6d
259fb40881f35f446700e5ef26d4d4b0cca3a0f6
We cannot bisect more!
error: bisect run cannot continue any more
```
<!-- /snippet -->

The log says why: the last good commit and the first testable bad commit are separated by four commits that the script had to skip.

<!-- snippet: ex2/solve-m11-judgekit/04-why -->
```text
$ git bisect log | grep "^# "
# bad: [6e67883ad93ca47c73f6a3ac0c0cb56acb4c9926] Add retries option to the judge client
# good: [eeead85a71dfe29e4971fe26609e22925da21490] Add judge agreement check with a golden set
# skip: [6f17e851a76c283b14a6f6b32990483f95308f98] Treat 'partially correct' as a pass
# skip: [0f15a4b3443008dc772e12e88fee209690cc7c2a] Add timeout option to the judge client
# bad: [0d5726542e789bd3836b498f22354ddca45ae7b1] Add a prompt that carries the rubric
# skip: [20d6e4843b4c96196ea4f1072619685b22a6d8d6] Accept lowercase verdicts
# good: [517dbd94fc21531508e5547fd4ed5f01f86e0e2e] Describe the golden set format
# skip: [d2d5498fa4c416cc45a4b48f9c3d989d83e49c6d] Move verdict parsing into judgekit/verdict.py
# bad: [259fb40881f35f446700e5ef26d4d4b0cca3a0f6] Fix import after the verdict module move
# good: [28a8db4d430e57a1fb7d1626f6f9365c54bff010] Add the grading prompt template
# only skipped commits left to test
# possible first 'bad' commit: [259fb40881f35f446700e5ef26d4d4b0cca3a0f6] Fix import after the verdict module move
# possible first 'bad' commit: [0f15a4b3443008dc772e12e88fee209690cc7c2a] Add timeout option to the judge client
# possible first 'bad' commit: [6f17e851a76c283b14a6f6b32990483f95308f98] Treat 'partially correct' as a pass
# possible first 'bad' commit: [20d6e4843b4c96196ea4f1072619685b22a6d8d6] Accept lowercase verdicts
# possible first 'bad' commit: [d2d5498fa4c416cc45a4b48f9c3d989d83e49c6d] Move verdict parsing into judgekit/verdict.py
$ git bisect reset
Previous HEAD position was 28a8db4 Add the grading prompt template
Switched to branch 'main'
$ git show --format='%h %s' 259fb40
259fb40 Fix import after the verdict module move

diff --git a/judgekit/agree.py b/judgekit/agree.py
index edebf2e..d50c79e 100644
--- a/judgekit/agree.py
+++ b/judgekit/agree.py
@@ -1,6 +1,6 @@
 """Agreement between judge verdicts and human labels."""
 
-from judgekit.parse import parse_verdict
+from judgekit.verdict import parse_verdict
 
 
 def agreement(rows):
```
<!-- /snippet -->

Between "Move verdict parsing into judgekit/verdict.py" and "Fix import after the verdict module move" the package cannot be imported. The fix for that is known: `259fb40`, a one-line change. So the untestable commits become testable if the fix is applied for the duration of each test and removed again:

<!-- snippet: ex2/solve-m11-judgekit/05-hotfix-script -->
```text
$ cat ../test-with-fix.sh
#!/bin/sh
# Same verdicts, but first apply the import fix 259fb40 where it is missing, and remove it afterwards.
if ! python3 -B -c 'import judgekit.agree' 2>/dev/null; then
  git cherry-pick --no-commit 259fb40 >/dev/null 2>&1 || { git reset -q --hard; exit 125; }
fi
../test-agreement.sh
rc=$?
git reset -q --hard
exit $rc
```
<!-- /snippet -->

<!-- snippet: ex2/solve-m11-judgekit/06-bisect-again -->
```text
$ git bisect start v1.1.0 v1.0.0
Bisecting: 6 revisions left to test after this (roughly 3 steps)
[6f17e851a76c283b14a6f6b32990483f95308f98] Treat 'partially correct' as a pass
$ git bisect run ../test-with-fix.sh
running '../test-with-fix.sh'
Bisecting: 2 revisions left to test after this (roughly 2 steps)
[28a8db4d430e57a1fb7d1626f6f9365c54bff010] Add the grading prompt template
running '../test-with-fix.sh'
Bisecting: 0 revisions left to test after this (roughly 1 step)
[20d6e4843b4c96196ea4f1072619685b22a6d8d6] Accept lowercase verdicts
running '../test-with-fix.sh'
6f17e851a76c283b14a6f6b32990483f95308f98 is the first 'bad' commit
commit 6f17e851a76c283b14a6f6b32990483f95308f98
Author: Asha Rao <asha@example.com>
Date:   Mon Sep 7 10:11:00 2026 +0530

    Treat 'partially correct' as a pass

 judgekit/verdict.py | 2 ++
 1 file changed, 2 insertions(+)
bisect found first 'bad' commit
```
<!-- /snippet -->

Three steps, one commit: `6f17e85`, "Treat 'partially correct' as a pass". Mark it, look at it, and repair `main` with a revert:

<!-- snippet: ex2/solve-m11-judgekit/07-mark -->
```text
$ git bisect reset
Previous HEAD position was 20d6e48 Accept lowercase verdicts
Switched to branch 'main'
$ git tag answer/first-bad 6f17e85
$ git show --format='%h %an: %s' answer/first-bad
6f17e85 Asha Rao: Treat 'partially correct' as a pass

diff --git a/judgekit/verdict.py b/judgekit/verdict.py
index 94d89d1..2893d7f 100644
--- a/judgekit/verdict.py
+++ b/judgekit/verdict.py
@@ -2,6 +2,8 @@
 
 
 def parse_verdict(text):
+    if text.strip().upper().startswith("PARTIALLY CORRECT"):
+        return "pass"
     words = text.strip().split()
     first = words[0].rstrip(":.,") if words else ""
     return "pass" if first.upper() == "PASS" else "fail"
```
<!-- /snippet -->

<!-- snippet: ex2/solve-m11-judgekit/08-fix -->
```text
$ git revert --no-edit answer/first-bad
[main 0f2a8c6] Revert "Treat 'partially correct' as a pass"
 Date: Mon Sep 7 10:39:00 2026 +0530
 1 file changed, 2 deletions(-)
$ python3 -B check_agreement.py
agreement 1.00
$ git log --oneline -3
0f2a8c6 Revert "Treat 'partially correct' as a pass"
6e67883 Add retries option to the judge client
e22fed4 Merge branch 'feat/rubric'
$ git status -sb
## main
$ cd ..
$ exercises/gen/m11-judgekit/check.sh
Checking exercise m11-judgekit
  ok    the tag answer/first-bad names the commit that lowered the agreement
  ok    no bisect session is open
  ok    HEAD is on main
  ok    the working tree is clean
  ok    no existing commit was rewritten (v1.1.0 is an ancestor of main)
  ok    the check prints agreement 1.00 on main
PASS: exercise m11-judgekit is complete.
[exit status: 0]
```
<!-- /snippet -->

The agreement is 1.00, higher than at `v1.0.0`, because "Accept lowercase verdicts" was an improvement that the regression had masked.

**Reasoning.** Bisect needs a property that is false at one end and true at the other, and a test with three answers. A crash is not the property, so it must be reported as 125, never as "bad". When the commit you are looking for sits among skipped commits, Git cannot decide and says so; it does not guess. The stretch of broken commits has a single cause with a known repair, which turns "cannot test" into "can test with a temporary change". The revert is the lowest-risk fix because `main` is shared history, the change is two added lines that nothing later depends on, and a revert is one new commit that can itself be reverted.

**Common mistakes.** Using the check's own exit status: it is always 0, so every commit is "good" and bisect names the wrong end. Counting the import error as bad: bisect then reports "Move verdict parsing into judgekit/verdict.py", which is precise, reproducible and wrong. Stopping at the list of five candidates and picking the one whose subject sounds guilty. Forgetting `git reset --hard` at the end of the script, so that the next checkout of bisect fails on a modified file. Leaving the session open: `git bisect reset` before you commit anything.

**Expert approach.** `git rev-list --count <good>..<bad>` first, for the cost. Write the three-way script before starting, and test it by hand on the good and on the bad end. When a run ends with "only skipped commits left", read `git bisect log`: it lists the candidates, and the first testable bad commit among them is usually the repair of the breakage, which is the hot-fix you need. Keep the two scripts outside the repository, so that checkouts do not replace them.

**Reference.** Chapter 14A, section 14A.20 (bisect, skip), section 14A.21 (`git bisect run`, exit status 125, what a crash counted as "bad" costs), section 14A.22 (pitfalls: skipped commits next to the culprit) and section 14A.25 ("only skipped commits left": test with the build fix applied temporarily). The script with a temporary modification follows the example "Automatically bisect with temporary modifications (hot-fix)" in `git help bisect`. Revert: Chapter 11, section 11.8.

### Exercise 11.10

**Solution.** Start with the shape and the tags:

<!-- snippet: ex2/solve-m11-vecindex/01-observe -->
```text
$ git log --graph --oneline --all
* 1e3540d Clamp top_k to the index size
* 1ef5794 Close the index file on error
* 9458cf3 Pin numpy for the 2.3 line
| * 20cd723 Add development requirements
| * 0b8f52c Mention recall@k in the README
| * eb295da Add recall@k metric
| * 50fdcc6 Clamp top_k to the index size
| * a292913 Close the index file on error
|/  
* 93d1bda Document the result order
* 22b909a Add brute-force search over a loaded index
$ git tag -l --format="%(refname:short) %(objecttype) %(*objectname:short) %(contents:subject)"
v2.3.0 tag 93d1bda vecindex 2.3.0
v2.3.1 tag 1ef5794 vecindex 2.3.1
v2.4.0 tag 0b8f52c vecindex 2.4.0
```
<!-- /snippet -->

Two commits carry the subject. Which refs contain each?

<!-- snippet: ex2/solve-m11-vecindex/02-two-commits -->
```text
$ git log --all --format='%h %an %s' --grep='Clamp top_k'
1e3540d Ravi Menon Clamp top_k to the index size
50fdcc6 Asha Rao Clamp top_k to the index size
$ git branch -a --contains 50fdcc6
* main
$ git tag --contains 50fdcc6
v2.4.0
$ git tag --contains 1e3540d
```
<!-- /snippet -->

The commit on `main`, `50fdcc6` by Asha, is in `v2.4.0` and in no 2.3 tag. The commit on the release branch, `1e3540d` by Ravi, is in no tag at all: it was made after `v2.3.1`. So the customer on 2.3.1 has neither. Are the two the same change?

<!-- snippet: ex2/solve-m11-vecindex/03-cherry -->
```text
$ git cherry -v release/2.3 main
- a29291343906fdd38c817e6710c1558727467850 Close the index file on error
+ 50fdcc6778cda4f3aea520272bafa8e622c5ab5b Clamp top_k to the index size
+ eb295daa80f6cf8e47125f0f64c39b367cfb2ebc Add recall@k metric
+ 0b8f52c4d34b5bcd9fa6994130c34f95b0fbdb13 Mention recall@k in the README
+ 20cd723836ce2096f5fbdcaeba122349412bef20 Add development requirements
$ git log --oneline --cherry-mark --left-right release/2.3...main
< 1e3540d Clamp top_k to the index size
= 1ef5794 Close the index file on error
< 9458cf3 Pin numpy for the 2.3 line
> 20cd723 Add development requirements
> 0b8f52c Mention recall@k in the README
> eb295da Add recall@k metric
> 50fdcc6 Clamp top_k to the index size
= a292913 Close the index file on error
```
<!-- /snippet -->

`git cherry` marks "Close the index file on error" with `-` (an equivalent patch is on the release branch) and the clamp fix with `+` (no equivalent). The two commits with the same subject are different patches:

<!-- snippet: ex2/solve-m11-vecindex/04-compare -->
```text
$ git show --format='%h %an: %s' --stat 1e3540d
1e3540d Ravi Menon: Clamp top_k to the index size

 vecindex/search.py | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)
$ git show --format='%h %an: %s' --stat 50fdcc6
50fdcc6 Asha Rao: Clamp top_k to the index size

 vecindex/search.py | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)
$ git range-diff 50fdcc6^! 1e3540d^!
1:  50fdcc6 ! 1:  1e3540d Clamp top_k to the index size
    @@
      ## Metadata ##
    -Author: Asha Rao <asha@example.com>
    +Author: Ravi Menon <ravi@example.com>
     
      ## Commit message ##
         Clamp top_k to the index size
     
    -    argpartition raises ValueError when top_k is not smaller than the number of rows. Small tenant indexes (fewer than ten documents) crashed every search and every batch search.
    -
      ## vecindex/search.py ##
     @@ vecindex/search.py: import numpy as np
      
    @@ vecindex/search.py: import numpy as np
          return order[np.argsort(-scores[order])]
      
      
    - def search_batch(index, queries, top_k=10):
    -+    top_k = min(top_k, len(index))
    -     scores = queries @ index.T
    --    order = np.argpartition(-scores, top_k, axis=1)[:, :top_k]
    -+    order = np.argpartition(-scores, top_k - 1, axis=1)[:, :top_k]
    -     return [row[np.argsort(-s[row])] for row, s in zip(order, scores)]
```
<!-- /snippet -->

Ravi's commit changes three lines, Asha's six. `git range-diff` shows what is missing: the whole hunk for `search_batch`. That is the function the customer reported.

<!-- snippet: ex2/solve-m11-vecindex/05-release-state -->
```text
$ git diff --stat v2.3.1 main -- vecindex/search.py
 vecindex/search.py | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)
$ git diff release/2.3 main -- vecindex/search.py
diff --git a/vecindex/search.py b/vecindex/search.py
index c83269e..1b46563 100644
--- a/vecindex/search.py
+++ b/vecindex/search.py
@@ -11,6 +11,7 @@ def search(index, query, top_k=10):
 
 
 def search_batch(index, queries, top_k=10):
+    top_k = min(top_k, len(index))
     scores = queries @ index.T
-    order = np.argpartition(-scores, top_k, axis=1)[:, :top_k]
+    order = np.argpartition(-scores, top_k - 1, axis=1)[:, :top_k]
     return [row[np.argsort(-s[row])] for row, s in zip(order, scores)]
```
<!-- /snippet -->

The facts:

| Ref | Complete fix? | Evidence |
|---|---|---|
| `main` | yes | `git branch --contains 50fdcc6` |
| `v2.4.0` | yes | `git tag --contains 50fdcc6` |
| `v2.3.1` | no, nothing | `git tag --contains` is empty for both commits; `git diff v2.3.1 main -- vecindex/search.py` shows all six lines |
| `release/2.3` | half | `git cherry` prints `+`; `git diff release/2.3 main -- vecindex/search.py` shows the `search_batch` hunk |

The backport is a cherry-pick of the real fix with `-x`. Half of it is already on the branch; the three-way merge recognizes identical changes and applies the rest:

<!-- snippet: ex2/solve-m11-vecindex/06-backport -->
```text
$ git tag answer/fix 50fdcc6
$ git switch release/2.3
Switched to branch 'release/2.3'
$ git cherry-pick -x answer/fix
Auto-merging vecindex/search.py
[release/2.3 e916873] Clamp top_k to the index size
 Author: Asha Rao <asha@example.com>
 Date: Mon Sep 7 10:08:00 2026 +0530
 1 file changed, 2 insertions(+), 1 deletion(-)
$ git show --stat --format="%h %s%n%n%b" HEAD
e916873 Clamp top_k to the index size

argpartition raises ValueError when top_k is not smaller than the number of rows. Small tenant indexes (fewer than ten documents) crashed every search and every batch search.

(cherry picked from commit 50fdcc6778cda4f3aea520272bafa8e622c5ab5b)


 vecindex/search.py | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)
```
<!-- /snippet -->

<!-- snippet: ex2/solve-m11-vecindex/07-verify -->
```text
$ git diff --stat main release/2.3 -- vecindex/search.py
$ git cherry -v release/2.3 main
- a29291343906fdd38c817e6710c1558727467850 Close the index file on error
+ 50fdcc6778cda4f3aea520272bafa8e622c5ab5b Clamp top_k to the index size
+ eb295daa80f6cf8e47125f0f64c39b367cfb2ebc Add recall@k metric
+ 0b8f52c4d34b5bcd9fa6994130c34f95b0fbdb13 Mention recall@k in the README
+ 20cd723836ce2096f5fbdcaeba122349412bef20 Add development requirements
$ git tag -a v2.3.2 -m 'vecindex 2.3.2: clamp top_k in search and in batch search'
$ git describe release/2.3
v2.3.2
$ git log --oneline v2.3.0..v2.3.2
e916873 Clamp top_k to the index size
1e3540d Clamp top_k to the index size
1ef5794 Close the index file on error
9458cf3 Pin numpy for the 2.3 line
$ git switch main
Switched to branch 'main'
$ cd ..
$ exercises/gen/m11-vecindex/check.sh
Checking exercise m11-vecindex
  ok    the tag answer/fix names the fix on main
  ok    vecindex/search.py on release/2.3 equals the fixed file on main
  ok    the earlier partial backport is still part of release/2.3
  ok    v2.3.1 is an ancestor of release/2.3
  ok    the backport records where it came from (cherry picked from ...)
  ok    main was not merged into release/2.3
  ok    v2.3.2 is an annotated tag
  ok    v2.3.2 names the tip of release/2.3
  ok    v2.3.1 still names the commit it was released from
  ok    no operation is left in progress
PASS: exercise m11-vecindex is complete.
[exit status: 0]
```
<!-- /snippet -->

The file now equals the one on `main` (empty diff), and `v2.3.2` is an annotated tag on the branch tip.

One line of the verification deserves attention: `git cherry` still prints `+` for the fix. The new commit on the release branch contains only the half that was missing, so its patch differs from the original and the patch IDs do not match. Equivalence by patch ID cannot see a backport that was split over two commits. The proof here is the empty `git diff` for the file and the `(cherry picked from commit ...)` line.

**Reasoning.** "Is the fix in the release?" is a question about a commit and a set of refs, and a subject line is not evidence for either. Three tools answer it with increasing strength: reachability (`--contains`), equivalence of the patch (`git cherry`, `--cherry-mark`), and content (`git diff` of the file between the release and a ref known to be fixed).

**Common mistakes.** Answering from `git log --grep` or from the subject, as support did. Reading "the commit is on `release/2.3`" as "it is in a 2.3 release": a branch moves, a release is a tag. Merging `main` into the release branch to get the fix, which ships every feature of 2.4 as a patch release. Cherry-picking without `-x`, after which the next person repeats this investigation. Moving `v2.3.1` to the new commit: a published tag stays where it is, and the fix gets a new version.

**Expert approach.** Find the fix once by content (`git log -S'min(top_k' --all`), then ask `git tag --contains` and `git branch -a --contains`. For a release branch, read `git log --oneline --cherry-mark --left-right release...main`: `=` is backported, `>` is not. After a backport, verify by content, not by subject, and tag.

**Reference.** Chapter 14A, section 14A.14 (`--cherry-mark`, `--left-right`) and section 14A.19 (`git tag --contains`). Chapter 10, section 10.9 (the backport workflow with `-x`, and a `+` from `git cherry` that is not what it seems) and section 10.10 (patch IDs). `git range-diff`: Chapter 9, section 9.14. Release branches and patch tags: Chapter 14B, sections 14B.8, 14B.11 and 14B.14.

### Exercise 11.11

**Solution.** First the observation, without anybody's interpretation. The value did change between the two deployments:

<!-- snippet: ex2/solve-m11-ragbench/01-observe -->
```text
$ git status -sb
## main...origin/main
$ git log --graph --oneline --decorate
* 6478b64 (HEAD -> main, tag: deploy-2026-09-11, origin/main) Mention reranking in the README
* fe77c55 Format the package with the new formatter
*   08aeddb Merge branch 'feat/rerank'
|\  
| * d03e252 Build the context from the reranked top
| * 4bda27f Add RERANK_TOP constant
| * ea97470 Add cross-encoder reranker
* | f192381 Tune retrieval constants
|/  
* 7142327 (tag: deploy-2026-09-04) Document the retrieval constants
* 164f7c6 Add retrieval and context building
$ git diff deploy-2026-09-04 deploy-2026-09-11 -- ragbench/retrieve.py | grep TOP_K
-TOP_K=20
+TOP_K = 5
-    hits=store.search(query,limit=TOP_K)
+    hits = store.search(query, limit=TOP_K)
```
<!-- /snippet -->

**The on-call notes.** Both observations are reproduced exactly:

<!-- snippet: ex2/solve-m11-ragbench/02-on-call-claims -->
```text
$ git blame -s -L 3,7 ragbench/retrieve.py
^164f7c6 3) # How many candidates the vector store returns, and the lowest score we keep.
fe77c554 4) TOP_K = 5
fe77c554 5) RERANK_TOP = 5
fe77c554 6) MIN_SCORE = 0.35
fe77c554 7) MAX_AGE_DAYS = 365
$ git log --oneline -S'TOP_K=5'
fe77c55 Format the package with the new formatter
```
<!-- /snippet -->

The observations are true. The conclusion drawn from them is tested next.

**Asha's claim.** "Whitespace only" is a statement about a diff, and `-w` tests it:

<!-- snippet: ex2/solve-m11-ragbench/03-asha -->
```text
$ git diff --stat fe77c55^ fe77c55
 ragbench/rerank.py   |  4 ++--
 ragbench/retrieve.py | 14 +++++++-------
 2 files changed, 9 insertions(+), 9 deletions(-)
$ git diff -w --stat fe77c55^ fe77c55
$ git show fe77c55^:ragbench/retrieve.py | grep TOP_K
TOP_K=5
    hits=store.search(query,limit=TOP_K)
$ git show --format='%h %an: %s' f192381 | grep '^[-+][A-Z]'
-MIN_SCORE=0.3
+MIN_SCORE=0.35
+MAX_AGE_DAYS=365
```
<!-- /snippet -->

With `-w` the diff of the formatter commit is empty. The value was already 5 in the parent of her commit, written as `TOP_K=5`. Her tuning commit changed `MIN_SCORE` and added `MAX_AGE_DAYS`, as she said. Asha is right on both counts, and reverting the formatter commit would bring back `TOP_K=5` without spaces.

**Ravi's claim.** His branch is deleted, but the merge commit still names it as its second parent:

<!-- snippet: ex2/solve-m11-ragbench/04-ravi -->
```text
$ git log --oneline 08aeddb^1..08aeddb^2
d03e252 Build the context from the reranked top
4bda27f Add RERANK_TOP constant
ea97470 Add cross-encoder reranker
$ git diff 08aeddb^1...08aeddb^2 -- ragbench/retrieve.py
diff --git a/ragbench/retrieve.py b/ragbench/retrieve.py
index 87efba8..33d3fd9 100644
--- a/ragbench/retrieve.py
+++ b/ragbench/retrieve.py
@@ -2,6 +2,7 @@
 
 # How many candidates the vector store returns, and the lowest score we keep.
 TOP_K=20
+RERANK_TOP=5
 MIN_SCORE=0.3
 
 
```
<!-- /snippet -->

Three commits, and the only change to the file is one added line, `RERANK_TOP=5`. Ravi is right too: no commit of his branch touched `TOP_K`.

So the value is 20 on `main` before the merge and 20 on the branch, and 5 one commit after the merge. Only one commit is left. Blame says so once the formatter is out of the way, and the pickaxe says so once it is told to look at merges:

<!-- snippet: ex2/solve-m11-ragbench/05-blame-through -->
```text
$ git blame -s -L 3,7 --ignore-rev fe77c55 ragbench/retrieve.py
^164f7c6 3) # How many candidates the vector store returns, and the lowest score we keep.
08aeddb6 4) TOP_K = 5
4bda27f5 5) RERANK_TOP = 5
f192381a 6) MIN_SCORE = 0.35
f192381a 7) MAX_AGE_DAYS = 365
$ git log --oneline -m -S'TOP_K=5'
fe77c55 Format the package with the new formatter
08aeddb (from f192381) Merge branch 'feat/rerank'
08aeddb (from d03e252) Merge branch 'feat/rerank'
```
<!-- /snippet -->

Bisect reaches the same commit with no knowledge of files or people:

<!-- snippet: ex2/solve-m11-ragbench/06-bisect -->
```text
$ git bisect start deploy-2026-09-11 deploy-2026-09-04
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[d03e252df19882739a5df880e8214d625c714d53] Build the context from the reranked top
$ git bisect run grep -q '^TOP_K *= *20' ragbench/retrieve.py
running 'grep' '-q' '^TOP_K *= *20' 'ragbench/retrieve.py'
Bisecting: 1 revision left to test after this (roughly 1 step)
[08aeddb6df6577ecc3d1b36303b71033691f070f] Merge branch 'feat/rerank'
running 'grep' '-q' '^TOP_K *= *20' 'ragbench/retrieve.py'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[f192381a4438f6141826e7b1200085b5ad987d03] Tune retrieval constants
running 'grep' '-q' '^TOP_K *= *20' 'ragbench/retrieve.py'
08aeddb6df6577ecc3d1b36303b71033691f070f is the first 'bad' commit
commit 08aeddb6df6577ecc3d1b36303b71033691f070f
Merge: f192381 d03e252
Author: Ravi Menon <ravi@example.com>
Date:   Wed Sep 9 10:17:00 2026 +0530

    Merge branch 'feat/rerank'

 ragbench/generate.py | 4 ++--
 ragbench/rerank.py   | 6 ++++++
 ragbench/retrieve.py | 3 ++-
 3 files changed, 10 insertions(+), 3 deletions(-)
 create mode 100644 ragbench/rerank.py
bisect found first 'bad' commit
$ git bisect reset
Previous HEAD position was f192381 Tune retrieval constants
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
```
<!-- /snippet -->

And the remerge diff shows what happened inside it:

<!-- snippet: ex2/solve-m11-ragbench/07-remerge -->
```text
$ git show --remerge-diff --format='%h %an: %s' 08aeddb -- ragbench/retrieve.py
08aeddb Ravi Menon: Merge branch 'feat/rerank'

diff --git a/ragbench/retrieve.py b/ragbench/retrieve.py
remerge CONFLICT (content): Merge conflict in ragbench/retrieve.py
index 1cfe089..9b08a8f 100644
--- a/ragbench/retrieve.py
+++ b/ragbench/retrieve.py
@@ -1,14 +1,10 @@
 """Candidate retrieval."""
 
 # How many candidates the vector store returns, and the lowest score we keep.
-TOP_K=20
-<<<<<<< f192381 (Tune retrieval constants)
+TOP_K=5
+RERANK_TOP=5
 MIN_SCORE=0.35
 MAX_AGE_DAYS=365
-=======
-RERANK_TOP=5
-MIN_SCORE=0.3
->>>>>>> d03e252 (Build the context from the reranked top)
 
 
 def retrieve(store,query):
```
<!-- /snippet -->

The two branches conflicted in the block of constants: `main` had changed `MIN_SCORE` and added `MAX_AGE_DAYS`, the branch had added `RERANK_TOP=5` at the same place. The line `TOP_K=20` was not part of the conflict. The resolution kept the right lines from both sides and also changed `TOP_K` to 5, most likely by typing the 5 of the new constant on the wrong line. A change that is in no parent, made in a merge commit: the glossary's "evil merge".

**Why the two tools of the on-call notes pointed elsewhere.** Blame names the last commit that changed the text of a line, and the formatter changed `TOP_K=5` to `TOP_K = 5`. The pickaxe search was for `TOP_K=5`: the formatter commit removed that string, so it is listed. The commit that introduced the string is a merge, and `git log` computes no diff for merges unless asked to (`-m`, `--first-parent`, `--remerge-diff`), so the pickaxe had nothing to search in.

**The decision.** The on-call proposal is declined: reverting the formatter commit fixes nothing and reintroduces unformatted code. Reverting the merge would remove the reranker, which is deployed and correct, and would create the re-merge problem. The lowest-risk change is one new commit that restores the line:

<!-- snippet: ex2/solve-m11-ragbench/08-fix -->
```text
$ git tag answer/culprit 08aeddb
# edit ragbench/retrieve.py: TOP_K = 20
$ git diff
diff --git a/ragbench/retrieve.py b/ragbench/retrieve.py
index cfbb6e2..4638158 100644
--- a/ragbench/retrieve.py
+++ b/ragbench/retrieve.py
@@ -1,7 +1,7 @@
 """Candidate retrieval."""
 
 # How many candidates the vector store returns, and the lowest score we keep.
-TOP_K = 5
+TOP_K = 20
 RERANK_TOP = 5
 MIN_SCORE = 0.35
 MAX_AGE_DAYS = 365
$ git commit -q -am 'Restore TOP_K to 20' -m 'The conflict resolution of the feat/rerank merge (08aeddb) wrote TOP_K=5. Neither side of the merge had asked for that value: main had 20, the branch had 20 and added RERANK_TOP=5.'
```
<!-- /snippet -->

**Prevention in the repository.** The conventional file, and the configuration that makes plain `git blame` use it:

<!-- snippet: ex2/solve-m11-ragbench/09-prevent -->
```text
# create .git-blame-ignore-revs with the full ID of the formatter commit
$ cat .git-blame-ignore-revs
fe77c554b8d2c7341b927d22f734ff11702db467   # Format the package with the new formatter
$ git add .git-blame-ignore-revs && git commit -q -m 'List the formatter commit for git blame to skip'
$ git config set blame.ignoreRevsFile .git-blame-ignore-revs
$ git blame -s -L 3,7 ragbench/retrieve.py
^164f7c6 3) # How many candidates the vector store returns, and the lowest score we keep.
5e25bdc5 4) TOP_K = 20
4bda27f5 5) RERANK_TOP = 5
f192381a 6) MIN_SCORE = 0.35
f192381a 7) MAX_AGE_DAYS = 365
```
<!-- /snippet -->

The file is committed and travels with the repository. `blame.ignoreRevsFile` is configuration, which does not travel: every clone sets it once (GitHub's blame view reads a file of this name without configuration, as Chapter 14A, section 14A.17 describes from the documentation).

<!-- snippet: ex2/solve-m11-ragbench/10-publish -->
```text
$ git log --oneline -4
a8227f2 List the formatter commit for git blame to skip
5e25bdc Restore TOP_K to 20
6478b64 Mention reranking in the README
fe77c55 Format the package with the new formatter
$ git push origin main
To ../server.git
   6478b64..a8227f2  main -> main
$ git status -sb
## main...origin/main
$ cd ..
$ exercises/gen/m11-ragbench/check.sh
Checking exercise m11-ragbench
  ok    the tag answer/culprit names the commit that changed the value
  ok    TOP_K is 20 again on main
  ok    the reranker constant, the tuned score and the age limit are still there
  ok    the formatting is still in place
  ok    the reranker is still on main
  ok    no published commit was rewritten (the deployed commit is an ancestor of main)
  ok    the ignore file .git-blame-ignore-revs is committed and lists the formatter commit
  ok    the fix is pushed (the server has your main)
  ok    the working tree is clean
  ok    no operation is left in progress
PASS: exercise m11-ragbench is complete.
[exit status: 0]
```
<!-- /snippet -->

**The four sentences for the channel.** Root cause: the conflict resolution of the `feat/rerank` merge (`08aeddb`) changed `TOP_K` from 20 to 5, a value neither branch contained; the formatter commit only re-spaced that line, which is why blame pointed at it. Fix: one commit on `main` restores `TOP_K = 20`; nothing was reverted and nothing was rewritten. Verification: `git bisect` between the two deployment tags names the merge, `git show --remerge-diff` shows the edit, and after the fix the file differs from last week's deployment only by the intended changes. Prevention: the formatter commit is listed in `.git-blame-ignore-revs`; conflict resolutions get reviewed with `git show --remerge-diff` before a merge is pushed; and a test that asserts the retrieval constants would have failed on Friday.

**Reasoning.** Three people made true statements that seemed to contradict the observation. When every commit of both branches is innocent and the result is wrong, the remaining place is the commit that has two parents and a tree of its own. A merge commit stores a snapshot, not a diff, so the tools that search diffs skip it by default.

**Common mistakes.** Acting on blame without reading the diff of the blamed commit. Believing that an empty pickaxe result means "nobody introduced it". Checking the branch with `git diff main feat/rerank` (two tips) instead of the three-dot form or `^1...^2`. Reverting the merge. Fixing the value with `git commit --amend` or a rebase on a branch that is deployed. Putting the short ID in `.git-blame-ignore-revs`: the file takes full object IDs.

**Expert approach.** Write the claims down as testable statements and test each one with a command, as above. Reach for bisect early: the property (`TOP_K` is 20) has a one-line test, there are ten commits, and bisect does not care how the value was changed. When bisect lands on a merge, `git show --remerge-diff` is the next command.

**Reference.** Chapter 14A, section 14A.16 and 14A.17 (blame, `-w`, `--ignore-rev`, `.git-blame-ignore-revs`, `blame.ignoreRevsFile`), section 14A.11 (the pickaxe), sections 14A.20 to 14A.22 (bisect) and section 14A.19 (the method). Chapter 8, section 8.15 (clean for Git, wrong for humans; evil merges) and section 8.16 (`git log -p` shows no diff for merges; `--remerge-diff`). Reverting a merge and the re-merge problem: Chapter 11, section 11.9. The `-m` option is described in `git help log` under "Diff Formatting".

---

## Module 12: Recovery

### Exercise 12.1

**Solution.**

<!-- snippet: ex2/answers-m12/12-1-reflog -->
```text
$ git log --oneline
3576459 Add README
6b46377 Add annotator roster
e800fb8 Add label schema
$ git reflog
3576459 HEAD@{0}: commit: Add README
6b46377 HEAD@{1}: reset: moving to HEAD~2
1fbf9ed HEAD@{2}: commit (amend): Add export script
7435d4c HEAD@{3}: commit: Add export script
fef57e2 HEAD@{4}: commit: Add agreement report
6b46377 HEAD@{5}: commit: Add annotator roster
e800fb8 HEAD@{6}: commit (initial): Add label schema
$ git reflog show main
3576459 main@{0}: commit: Add README
6b46377 main@{1}: reset: moving to HEAD~2
1fbf9ed main@{2}: commit (amend): Add export script
7435d4c main@{3}: commit: Add export script
fef57e2 main@{4}: commit: Add agreement report
6b46377 main@{5}: commit: Add annotator roster
e800fb8 main@{6}: commit (initial): Add label schema
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m12/12-1-on-disk -->
```text
$ tail -2 .git/logs/HEAD
1fbf9ed528f5ad80af88f68651fc64d187ffd188 6b463775cf79d4f48e602f58b57c9dec19b3ffb3 Lab User <you@example.com> 1788755880 +0530	reset: moving to HEAD~2
6b463775cf79d4f48e602f58b57c9dec19b3ffb3 3576459b39fa9058263049ccfc5f7826b92a6e27 Lab User <you@example.com> 1788755940 +0530	commit: Add README
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m12/12-1-rescue -->
```text
$ git branch rescue 'HEAD@{2}'
$ git log --oneline main..rescue
1fbf9ed Add export script
fef57e2 Add agreement report
$ git diff --stat main...rescue
 reports/agreement.md | 3 +++
 scripts/export.sh    | 3 +++
 2 files changed, 6 insertions(+)
```
<!-- /snippet -->

1. `HEAD@{2}`, "commit (amend): Add export script", is the state before the accident. The accident is the entry above it, `HEAD@{1}: reset: moving to HEAD~2`.
2. "Add export script" was committed as `7435d4c` and then amended, which created `1fbf9ed`; the first one stayed in the object database. You rescued the amended one, the final form.
3. The value of `HEAD` before and after the operation. The second transcript shows the reset: from `1fbf9ed` to `6b46377`.
4. A branch adds a name and changes nothing else. `git reset --hard 'HEAD@{2}'` would have moved `main` away from the commit "Add README", which was made after the accident, and would have overwritten the working tree.
5. 90 days for reflog entries whose commit is reachable from the current tip and 30 days for entries whose commit is not, which is the case here (`gc.reflogExpire`, `gc.reflogExpireUnreachable`); after that the next garbage collection may delete the objects once they are older than two weeks (`gc.pruneExpire`). The lab configuration sets the first two to `never`.

**Reasoning.** `git reset --hard` moved a ref. It deleted no object. The reflog recorded the old value of the ref, and a branch at that value makes the commits reachable again. The three-dot diff confirms what the rescue contains.

**Common mistakes.** Counting selectors from the wrong end: `HEAD@{0}` is the present. Rescuing `HEAD@{3}`, the pre-amend commit, and losing the amendment. Quoting: `HEAD@{2}` needs quotes in zsh. Resetting before anchoring.

**Expert approach.** `git reflog show main` when the question is about a branch: the branch's own reflog has no checkout noise. Anchor with `git branch rescue <id>`, compare with `git log main..rescue`, and only then decide between cherry-pick, merge and reset.

**Reference.** Chapter 13, section 13.3 (the reflog and its file format), section 13.4 (retention), section 13.7 (the recovery method) and section 13.8 (an accidental reset).

### Exercise 12.2

**Solution.**

<!-- snippet: ex2/answers-m12/12-2-backup -->
```text
$ git log --oneline main..HEAD
b5e941a Cover quoted content
8dca71d Say how to break ties
0c7d254 Add labelling guidelines
$ git branch backup/pre-squash
$ git reset --soft main && git commit -q -m 'Add guidelines'
$ git log --oneline main..HEAD
83c2dea Add guidelines
$ git rev-parse --short ORIG_HEAD
b5e941a
$ git rev-parse --short backup/pre-squash
b5e941a
$ git diff --stat backup/pre-squash HEAD
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m12/12-2-restore -->
```text
$ git reset --hard backup/pre-squash
HEAD is now at b5e941a Cover quoted content
$ git log --oneline main..HEAD
b5e941a Cover quoted content
8dca71d Say how to break ties
0c7d254 Add labelling guidelines
$ git rev-parse --short ORIG_HEAD
83c2dea
$ git branch -d backup/pre-squash
Deleted branch backup/pre-squash (was b5e941a).
```
<!-- /snippet -->

1. After the restore `ORIG_HEAD` names `83c2dea`, the squashed commit: the second reset overwrote the slot with the position it moved away from. `ORIG_HEAD` is one slot that several commands write. It is good for the command you ran a moment ago and worthless as a backup.
2. That the squashed commit has exactly the same tree as the original tip. The squash changed history and no content.
3. The working tree was clean (the reset would otherwise have discarded changes without a trace), and the target was a branch you had created for this purpose, so nothing depended on a reflog position.
4. `83c2dea`, the squashed commit. The three original commits are on the branch again.

**Reasoning.** A backup branch costs one small file and gives the pre-operation state a name that does not move. The reflog gives you the same commit, but under a selector that shifts with every further operation.

**Common mistakes.** `git rev-parse --short ORIG_HEAD backup/pre-squash` fails on Git 2.55 with "Needed a single revision": `--short` accepts one revision, which is why the transcript uses two commands. Using `ORIG_HEAD` an hour and three commands later. Forgetting to delete the backup branch, or deleting it before the result is verified.

**Expert approach.** Name backups by purpose (`backup/<what>-before-<operation>`), verify the result against the name (`git diff --stat`, `git range-diff`), delete the name when the result is pushed.

**Reference.** Chapter 13, section 13.5 (`ORIG_HEAD`: one slot, written by four commands) and section 13.14 (backup refs). `git reset --soft`: Chapter 11, section 11.4.

### Exercise 12.3

**Solution.**

<!-- snippet: ex2/answers-m12/12-3-fsck -->
```text
$ git fsck
dangling blob 817591d65181a652d51006d5cd7c959e0080c694
dangling commit 08d9c7e04d09c8b2d4edc22019c389ef678ad46e
$ git fsck --no-reflogs
dangling blob 817591d65181a652d51006d5cd7c959e0080c694
dangling commit 08d9c7e04d09c8b2d4edc22019c389ef678ad46e
dangling commit db8e41ab4fa9537963db725a98de2e18f01c0775
$ git fsck --unreachable --no-reflogs | sort
unreachable blob 46e4db03d516a7f84b68b9df96c8be183ed5af57
unreachable blob 62c4ba4a63cc0605ca3c64be72ed33592d2654d7
unreachable blob 817591d65181a652d51006d5cd7c959e0080c694
unreachable blob 8fd80764378b505ba0e78cf566d39cd5ed06f3c7
unreachable commit 08d9c7e04d09c8b2d4edc22019c389ef678ad46e
unreachable commit 526c0eb4d0274150b277530ee1d9b1fe1f7cf932
unreachable commit db8e41ab4fa9537963db725a98de2e18f01c0775
unreachable commit df5e1986bde6842bce252b00cddd89e476c7fe1f
unreachable tree 345b5a941fd76fa280898a86ce7a19e1bfb1ddaa
unreachable tree b7cce6aedbe39b4d32d0af043357d7d10bd5adc2
unreachable tree d7d6e5ed9116b188100d0bb2d019c1f55e39d923
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m12/12-3-identify -->
```text
$ git fsck --lost-found
dangling blob 817591d65181a652d51006d5cd7c959e0080c694
dangling commit 08d9c7e04d09c8b2d4edc22019c389ef678ad46e
dangling commit db8e41ab4fa9537963db725a98de2e18f01c0775
$ ls .git/lost-found/commit .git/lost-found/other
.git/lost-found/commit:
08d9c7e04d09c8b2d4edc22019c389ef678ad46e
db8e41ab4fa9537963db725a98de2e18f01c0775

.git/lost-found/other:
817591d65181a652d51006d5cd7c959e0080c694
$ git show -s --format='%h %p | %s' 08d9c7e
08d9c7e 8c9da89 df5e198 | On main: roster with meera
$ git show -s --format='%h %p | %s' db8e41a
db8e41a 526c0eb | Raise the severity of spam
$ git cat-file -p 817591d
kappa: 0.71
```
<!-- /snippet -->

1. `08d9c7e` is the dropped stash, `db8e41a` the tip of the deleted branch. By default `git fsck` treats reflog entries as starting points. The branch's commits were made while the branch was checked out, so the HEAD reflog still names them and they count as reachable. Dropping a stash deletes its reflog entry, and nothing else ever named the stash commit.
2. Unreachable: no ref (and, with `--no-reflogs`, no reflog entry) leads to the object. Dangling: unreachable, and no other unreachable object refers to it either. Eleven objects are unreachable here; three of them are dangling. The rest hang off those three: the first commit of the branch under its tip, the stash's index commit under the stash commit, and their trees and blobs.
3. A stash entry: its first parent is the commit you were on, its second parent a commit that records the index.
4. `--no-reflogs`: its output has the same three lines. It wrote the IDs as empty-named files under `.git/lost-found/commit` and the blob's content under `.git/lost-found/other`.
5. `missing`, `broken link`, `corrupt`, and anything that begins with `error:`.

**Reasoning.** `git fsck` walks from the refs and reports what it cannot reach. What it calls dangling is the top of each lost structure, which is why the dangling list is the place to start a search: three lines here, eleven with `--unreachable`.

**Common mistakes.** Reading "dangling" as damage. Searching the long unreachable list by hand. Running `git gc --prune=now` "to clean up the warnings", which deletes exactly the objects you might want. Expecting the blob to have a name: file names live in trees, and this blob was staged and replaced before any tree was written.

**Expert approach.** `git fsck --lost-found`, then one loop: `git show -s --format='%h %ci %s'` over the commits, `git cat-file -p` over the blobs. For a stash, the subject starts with "WIP on" or "On"; `git stash apply <id>` restores it without the reflog.

**Reference.** Chapter 13, section 13.6 (`git fsck` as a search tool: dangling, unreachable, `--no-reflogs`, `--lost-found`), section 13.8 (a deleted branch) and section 13.9 (a dropped stash, a staged file).

### Exercise 12.4

**Solution.** The setup:

<!-- snippet: ex2/answers-m12/12-4-setup -->
```text
$ git init -q reflog-lab && cd reflog-lab
$ echo one > f.txt && git add f.txt && git commit -q -m A
$ echo two >> f.txt && git commit -q -am B
$ git commit -q --amend -m 'B, reworded'
$ git reset --soft HEAD~1
$ git commit -q -m C
$ git switch -q -c topic
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m12/12-4-answer -->
```text
$ git reflog
704c1b8 HEAD@{0}: checkout: moving from main to topic
704c1b8 HEAD@{1}: commit: C
056e033 HEAD@{2}: reset: moving to HEAD~1
28b10aa HEAD@{3}: commit (amend): B, reworded
5f7db36 HEAD@{4}: commit: B
056e033 HEAD@{5}: commit (initial): A
$ git reflog show main
704c1b8 main@{0}: commit: C
056e033 main@{1}: reset: moving to HEAD~1
28b10aa main@{2}: commit (amend): B, reworded
5f7db36 main@{3}: commit: B
056e033 main@{4}: commit (initial): A
$ git reflog show topic
704c1b8 topic@{0}: branch: Created from HEAD
$ git rev-list --count HEAD
2
$ git cat-file --batch-check --batch-all-objects | grep -c ' commit '
4
```
<!-- /snippet -->

1. Six lines: one per movement of `HEAD`, newest first. `checkout: moving from main to topic`, `commit: C`, `reset: moving to HEAD~1`, `commit (amend): B, reworded`, `commit: B`, `commit (initial): A`.
2. Five for `main`, one for `topic`. The switch moved `HEAD` and no branch, so it is missing from the reflog of `main`; `topic` has the single entry of its creation.
3. Two: A and C.
4. Four commit objects: A, B, the reworded B, and C. No branch reaches B or the reworded B; they are held by the reflogs only.

**Reasoning.** The HEAD reflog records every movement of `HEAD`, a branch reflog every movement of that branch. An amend creates a new commit and leaves the old one. `git reset --soft HEAD~1` moved `main` back to A and left the index as it was, so C contains the content of B with the message C.

**Common mistakes.** Expecting the amend to replace B. Expecting `topic` to inherit the reflog of `main`. Writing seven lines, with one for `git init`: an unborn branch has no value to record. Counting three commits on `HEAD`.

**Expert approach.** Read reflog lines as a log of ref updates with a reason, and predict them from "which ref moved". That habit makes a real reflog readable at speed when something is lost.

**Reference.** Chapter 13, section 13.3. Amend creates a new commit: Chapter 6 and Chapter 11, section 11.7.

### Exercise 12.5

**Solution.**

<!-- snippet: ex2/answers-m12/12-5-one-file -->
```text
$ git reflog -3
4a9e70c HEAD@{0}: commit (amend): Add label schema
09a39e3 HEAD@{1}: commit: Add label schema
3efa88d HEAD@{2}: commit (initial): Add README
$ git diff --stat 'HEAD@{1}' HEAD
 README.md          | 2 ++
 schema/labels.yaml | 5 -----
 2 files changed, 2 insertions(+), 5 deletions(-)
$ git restore --source='HEAD@{1}' -- schema/labels.yaml
$ git status -sb
## main
 M schema/labels.yaml
$ tail -5 schema/labels.yaml
deprecated:
  - id: offensive
    replaced_by: toxic
  - id: advert
    replaced_by: spam
$ git reflog -1
4a9e70c HEAD@{0}: commit (amend): Add label schema
```
<!-- /snippet -->

`HEAD@{1}` is the commit before the amend. `git restore --source='HEAD@{1}' -- schema/labels.yaml` copies one path from it into the working tree. The file shows as modified against `HEAD`, the amended `README.md` is untouched, and the reflog still ends with the amend: no ref moved.

**Reasoning.** Recovery does not have to be all or nothing. A reflog selector names a commit like any other revision, and every command that reads from a commit accepts it.

**Common mistakes.** `git reset --hard 'HEAD@{1}'`, which also brings back the old `README.md` and discards the amended commit from the branch. `git checkout 'HEAD@{1}'`, which detaches `HEAD`. Adding `--staged` when the task says working tree only. Using `HEAD~1`: the pre-amend commit is not an ancestor of `HEAD`, it is a sibling.

**Expert approach.** Look before copying: `git diff --stat 'HEAD@{1}' HEAD` shows what the amend changed, `git show 'HEAD@{1}:schema/labels.yaml'` shows the old content. `git restore -p --source='HEAD@{1}' -- <path>` takes single hunks.

**Reference.** Chapter 13, section 13.3 (selectors) and section 13.8. `git restore --source`: Chapter 11, section 11.3.

### Exercise 12.6

**Solution.**

<!-- snippet: ex2/answers-m12/12-6-commands -->
```text
$ git log --oneline
24f566e D export
db89a1d C report
7fce54f B roster
c69afce A schema
$ git reset --hard HEAD~2
HEAD is now at 7fce54f B roster
$ echo 'E readme' > readme.txt && git add readme.txt && git commit -q -m 'E readme'
$ git branch rescue 'main@{2}'
```
<!-- /snippet -->

Graph 1:

<!-- snippet: ex2/answers-m12/12-6-graph-1 -->
```text
$ git log --graph --oneline --all
* db9c60d E readme
| * 24f566e D export
| * db89a1d C report
|/  
* 7fce54f B roster
* c69afce A schema
```
<!-- /snippet -->

Graph 2, after the rebase:

<!-- snippet: ex2/answers-m12/12-6-graph-2 -->
```text
$ git rebase rescue
Rebasing (1/1)
Successfully rebased and updated refs/heads/main.
$ git log --graph --oneline --all
* 32079fa E readme
* 24f566e D export
* db89a1d C report
* 7fce54f B roster
* c69afce A schema
$ git reflog -3
32079fa HEAD@{0}: rebase (finish): returning to refs/heads/main
32079fa HEAD@{1}: rebase (pick): E readme
24f566e HEAD@{2}: rebase (start): checkout rescue
```
<!-- /snippet -->

The selector is `main@{2}` because two things happened to `main` after it pointed at D: the reset (now `main@{1}`, pointing at B) and the commit of E (now `main@{0}`). After the rebase the original E, `db9c60d` in graph 1, is reachable from no branch: the rebase created a new commit `32079fa` with the same change on top of D.

**Reasoning.** The reset moved `main` from D to B and left C and D unreachable from any branch. E was committed on B. `rescue` gives C and D a name again, which makes the history fork at B. The rebase replays E onto `rescue`, and since `main` then contains `rescue`, the graph is one line.

**Common mistakes.** Drawing E on top of D in graph 1. Using `main@{1}`. Drawing the rebased E with the old ID: a commit with another parent is another commit. Believing that the old E is gone: the reflog of `main` and of `HEAD` still holds it.

**Expert approach.** `git rebase rescue` was one of three ways to finish. `git merge rescue` keeps both lines and adds a merge commit; `git cherry-pick main@{2}~1 main@{2}`, run before the branch was created, would have copied C and D after E. Choose by what the history should say, and delete `rescue` afterwards.

**Reference.** Chapter 13, section 13.8. Why a rebased commit has a new ID: Chapter 9, section 9.3.

### Exercise 12.7

**Solution.**

<!-- snippet: ex2/answers-m12/12-7-diagnose -->
```text
$ git status -sb
## main...origin/main [ahead 1, behind 1]
$ git push
To ../server.git
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
[exit status: 1]
$ git reflog -3
f4c9756 HEAD@{0}: commit (amend): Add JSON export of the schema
fc3c42d HEAD@{1}: commit: Add JSON export of the schema
c79146c HEAD@{2}: commit (initial): Add label schema
$ git log --graph --oneline --all
* f4c9756 Add JSON export of the schema
| * fc3c42d Add JSON export of the schema
|/  
* c79146c Add label schema
$ git diff --stat origin/main HEAD
 scripts/validate.py | 4 ++++
 1 file changed, 4 insertions(+)
```
<!-- /snippet -->

The reflog has it: `commit (amend): Add JSON export of the schema`. You staged the new script and ran `git commit --amend`, which replaced the tip `fc3c42d` with a new commit `f4c9756` that contains the old change and the new file. The server still has `fc3c42d`. The two commits are siblings, which is "ahead 1, behind 1", and a push would have to discard the server's commit, so it is rejected.

<!-- snippet: ex2/answers-m12/12-7-fix -->
```text
$ git reset --soft origin/main
$ git status -sb
## main...origin/main
A  scripts/validate.py
$ git commit -m 'Add schema validation script'
[main 45462e2] Add schema validation script
 1 file changed, 4 insertions(+)
 create mode 100644 scripts/validate.py
$ git log --graph --oneline --all
* 45462e2 Add schema validation script
* fc3c42d Add JSON export of the schema
* c79146c Add label schema
$ git push
To ../server.git
   fc3c42d..45462e2  main -> main
```
<!-- /snippet -->

`git reset --soft origin/main` moves `main` back to the pushed commit and leaves index and working tree alone. The index still holds the tree of the amended commit, so the only staged difference is the new script. One commit, and the push is a fast-forward.

`git pull` would have merged the pushed commit with its amended twin. The merge succeeds, because both contain the same change to the same files, and the push is then accepted. The history would hold the export change twice plus a merge that merges nothing: correct content, false history, and a confusing diff for the next reader.

**Reasoning.** An amend rewrites the tip. Rewriting a commit that is already on the server makes your branch diverge from it. The repair is to undo the rewrite and keep the content: move the branch, not the files.

**Common mistakes.** `git push --force`: on `main` that rewrites shared history for everyone who fetched. `git pull` and push. `git reset --hard origin/main`, which deletes the new script from the working tree (it would still be in the amended commit, reachable through the reflog). `git reset --mixed`, which is harmless here but leaves the script untracked instead of staged.

**Expert approach.** Read `[ahead 1, behind 1]` right after a commit as "I rewrote something that was pushed", and confirm with `git reflog -3` and `git diff --stat origin/main HEAD`. Then `git reset --soft @{u}` and commit.

**Reference.** Chapter 11, section 11.7 (`git commit --amend` is a soft reset plus a new commit), section 11.4 (`--soft`) and section 11.13 (the deciding question: private or shared history). The rejection message: Chapter 12, section 12.7.

### Exercise 12.8

**Solution.**

<!-- snippet: ex2/answers-m12/12-8-diagnose -->
```text
$ git clone backup.bundle restored
Cloning into 'restored'...
error: Repository lacks these prerequisite commits:
error: 5a703da656b0bc3bc4bfec21207dc964d506f7be 
fatal: remote transport reported error
[exit status: 128]
$ git bundle list-heads backup.bundle
377fe7fc435cc7e1ed37f33c5274c5659206aa1c refs/heads/feature/consensus
7ace9752776b1daad49869373229f0d168597285 refs/heads/spike/weights
$ sed -n 1,2p backup.bundle
# v2 git bundle
-5a703da656b0bc3bc4bfec21207dc964d506f7be Add annotator roster
```
<!-- /snippet -->

The bundle holds two branches and names one prerequisite: the line that starts with `-` in its header is a commit the bundle does not contain and expects the receiving repository to have. It was made from a range (everything on the branches that is not on `origin/main`), so it is an incremental bundle. A clone starts from an empty repository, which has nothing, so the prerequisite is missing.

The prerequisite is "Add annotator roster", a commit of `main`, and the server has it:

<!-- snippet: ex2/answers-m12/12-8-restore -->
```text
$ git clone -q server.git restored && cd restored
$ git bundle verify ../backup.bundle
../backup.bundle is okay
The bundle contains these 2 refs:
377fe7fc435cc7e1ed37f33c5274c5659206aa1c refs/heads/feature/consensus
7ace9752776b1daad49869373229f0d168597285 refs/heads/spike/weights
The bundle requires this ref:
5a703da656b0bc3bc4bfec21207dc964d506f7be 
The bundle uses this hash algorithm: sha1
$ git fetch ../backup.bundle 'refs/heads/*:refs/heads/*'
From ../backup.bundle
 * [new branch]      spike/weights     -> spike/weights
 * [new branch]      feature/consensus -> feature/consensus
$ git log --graph --oneline --all
* f114886 Add meera to the roster
| * 7ace975 Try annotator weights
|/  
| * 377fe7f Return no label without a strict majority
| * 648b8df Add majority vote
|/  
* 5a703da Add annotator roster
* 70a7350 Add label schema
```
<!-- /snippet -->

Clone the server first, verify the bundle inside that clone ("is okay"), then fetch the bundle's branches into local branches. The graph shows both unpushed branches again, attached to the commit of `main` they were made from, and the newer commit that a teammate pushed in the meantime.

What the bundle could not save: anything that was not committed when it was written (the working tree, the index), stashes and the reflogs, unless they were named on the command line, and every commit made after the nightly run.

**Reasoning.** A bundle is a pack with a list of refs and a list of prerequisites. `git bundle create <file> <old>..<new>` stores only what the range adds. That keeps a nightly backup small, and it makes the backup depend on the receiving repository having `<old>`.

**Common mistakes.** Concluding that the bundle is damaged. Fetching without a refspec, which leaves the result in `FETCH_HEAD` only. Fetching into `refs/remotes/...` and then forgetting to create branches. Skipping `git bundle verify`, which tells you in one line whether this repository can use the file.

**Expert approach.** Decide what the backup is for. For "everything on this machine", `git bundle create <file> --all` is self-contained and clones anywhere. For nightly increments, keep the full bundle the increments are based on, or make sure the base is on the server, and test the restore once before you need it.

**Reference.** Chapter 13, section 13.14 (bundles as backups, `verify`, `list-heads`). Chapter 26, section 26.14 (bundles made from a range, prerequisites, the error message).

### Exercise 12.9

**Solution.**

<!-- snippet: ex2/solve-m12-batchscore/01-observe -->
```text
$ git status -sb
## feature/retry-budget
$ git branch -vv
* feature/retry-budget e3fa4c5 Log the retry budget at startup
  main                 c2f3aa1 [origin/main] Say how to run the job
$ git log --graph --oneline --all
* e3fa4c5 Log the retry budget at startup
* c2f3aa1 Say how to run the job
* a2f9ca2 Add README
* f98428f Add batch scoring worker
```
<!-- /snippet -->

The branch is `main` plus one commit, as reported. The HEAD reflog agrees with Ravi's account, and `ORIG_HEAD` is a false trail:

<!-- snippet: ex2/solve-m12-batchscore/02-head-reflog -->
```text
$ git reflog -9
e3fa4c5 HEAD@{0}: commit: Log the retry budget at startup
c2f3aa1 HEAD@{1}: checkout: moving from main to feature/retry-budget
c2f3aa1 HEAD@{2}: pull: Fast-forward
a2f9ca2 HEAD@{3}: checkout: moving from feature/retry-budget to main
f03be39 HEAD@{4}: commit (amend): Refuse to retry when the budget is spent
c65af24 HEAD@{5}: commit: Refuse to retry when the budget is spent
4636c8d HEAD@{6}: commit: Spend the budget per batch
4471233 HEAD@{7}: commit: Add retry budget
a2f9ca2 HEAD@{8}: checkout: moving from main to feature/retry-budget
$ git log -1 --format="%h %s" ORIG_HEAD
a2f9ca2 Add README
```
<!-- /snippet -->

A pull and two checkouts, no reset, no rebase. The three commits are there, further down. `ORIG_HEAD` points at the old `main`, written by the pull. The line that matters is `HEAD@{1}`: a checkout "from main to feature/retry-budget" whose resulting commit is the tip of `main`, not the tip the branch had at `HEAD@{4}`. The branch's own reflog says what moved it:

<!-- snippet: ex2/solve-m12-batchscore/03-branch-reflog -->
```text
$ git reflog show feature/retry-budget
e3fa4c5 feature/retry-budget@{0}: commit: Log the retry budget at startup
c2f3aa1 feature/retry-budget@{1}: branch: Reset to HEAD
f03be39 feature/retry-budget@{2}: commit (amend): Refuse to retry when the budget is spent
c65af24 feature/retry-budget@{3}: commit: Refuse to retry when the budget is spent
4636c8d feature/retry-budget@{4}: commit: Spend the budget per batch
4471233 feature/retry-budget@{5}: commit: Add retry budget
a2f9ca2 feature/retry-budget@{6}: branch: Created from HEAD
```
<!-- /snippet -->

`branch: Reset to HEAD`. That is what `git switch -C <branch>` (older: `git checkout -B`) writes: create the branch at the current commit, and if it exists, reset it. Ravi typed `-C` where he meant no option, or `-c`. Anchor the entry before it:

<!-- snippet: ex2/solve-m12-batchscore/04-anchor -->
```text
$ git branch rescue 'feature/retry-budget@{2}'
$ git log --oneline main..rescue
f03be39 Refuse to retry when the budget is spent
4636c8d Spend the budget per batch
4471233 Add retry budget
$ git show rescue:batchscore/worker.py | grep budget.left
    if budget is not None and budget.left <= 0:
```
<!-- /snippet -->

Three commits, with the final form of the third (`<= 0`, the amended version). Now rebuild the branch: first move this morning's commit onto the rescued commits, then bring the whole branch onto the current `main`.

<!-- snippet: ex2/solve-m12-batchscore/05-rebuild -->
```text
$ git rebase --onto rescue main feature/retry-budget
Rebasing (1/1)
Successfully rebased and updated refs/heads/feature/retry-budget.
$ git rebase main
Rebasing (1/4)
Rebasing (2/4)
Rebasing (3/4)
Rebasing (4/4)
Successfully rebased and updated refs/heads/feature/retry-budget.
$ git log --graph --oneline --all
* e670eeb Log the retry budget at startup
* ea83af7 Refuse to retry when the budget is spent
* d13e40d Spend the budget per batch
* 896590f Add retry budget
* c2f3aa1 Say how to run the job
| * f03be39 Refuse to retry when the budget is spent
| * 4636c8d Spend the budget per batch
| * 4471233 Add retry budget
|/  
* a2f9ca2 Add README
* f98428f Add batch scoring worker
```
<!-- /snippet -->

<!-- snippet: ex2/solve-m12-batchscore/06-verify -->
```text
$ git range-diff rescue~3..rescue main..HEAD~1
1:  4471233 = 1:  896590f Add retry budget
2:  4636c8d = 2:  d13e40d Spend the budget per batch
3:  f03be39 = 3:  ea83af7 Refuse to retry when the budget is spent
$ git diff --stat rescue HEAD
 README.md          | 2 ++
 batchscore/main.py | 4 ++--
 2 files changed, 4 insertions(+), 2 deletions(-)
$ git branch -D rescue
Deleted branch rescue (was f03be39).
$ git status -sb
## feature/retry-budget
$ cd ..
$ exercises/gen/m12-batchscore/check.sh
Checking exercise m12-batchscore
  ok    the commit "Add retry budget" is on feature/retry-budget exactly once
  ok    the commit "Spend the budget per batch" is on feature/retry-budget exactly once
  ok    the commit "Refuse to retry when the budget is spent" is on feature/retry-budget exactly once
  ok    the commit "Log the retry budget at startup" is on feature/retry-budget exactly once
  ok    this morning's commit is the tip of the branch
  ok    the branch contains the current main of the server
  ok    the worker has the final form of the budget check (<= 0)
  ok    the budget class is back
  ok    HEAD is on the branch
  ok    the working tree is clean
  ok    no operation is left in progress
PASS: exercise m12-batchscore is complete.
[exit status: 0]
```
<!-- /snippet -->

`git range-diff` shows `=` for all three commits: same changes, new IDs because of the new base. The diff between the rescued tip and the branch is this morning's commit and the update of `main`, nothing else.

**What to tell Ravi.** The command was `git switch -C feature/retry-budget`, run while on `main`. Nothing was deleted: the branch ref was moved, and Git recorded the old value in `.git/logs/refs/heads/feature/retry-budget`. The HEAD reflog showed "a checkout" because that is what `HEAD` did.

**Reasoning.** `HEAD` and a branch are two refs with two reflogs. `switch -C` moves the branch and then checks it out; the HEAD reflog records the second half only. When a branch has the wrong value and the HEAD reflog shows nothing unusual, ask the branch.

**Common mistakes.** Trusting `ORIG_HEAD`. Taking `feature/retry-budget@{3}`, the commit before the amend. Resetting the branch to the rescued commit, which drops this morning's commit from the branch. Cherry-picking the three commits on top of this morning's commit: the content is right and the order is wrong. Forgetting the second rebase, which leaves the branch on the old `main`.

**Expert approach.** `git reflog show <branch>` first for any question about one branch. One command would do the rebuild: `git rebase --onto main rescue~3 rescue` followed by a cherry-pick of this morning's commit, but two small rebases with a check in between are easier to verify. Prevention: `-C` and `-B` are force flags; an alias or habit that uses them to "go to my branch" will do this again.

**Reference.** Chapter 13, section 13.3 (HEAD reflog and branch reflogs), section 13.5 (`ORIG_HEAD` is overwritten by later commands) and sections 13.7 and 13.8. `git switch -C`: Chapter 7, section 7.6. `git rebase --onto`: Chapter 9, section 9.5; `git range-diff`: section 9.14.

### Exercise 12.10

**Solution.**

<!-- snippet: ex2/solve-m12-embedcache/01-observe -->
```text
$ git status -sb
## feature/lru-cache
$ git stash list
$ git log --oneline main..HEAD
c5bdfe4 Add LRU eviction
0da6724 Normalize the model name in the key
d7b7ce8 Add cache key builder
$ git reflog show feature/lru-cache
c5bdfe4 feature/lru-cache@{0}: commit: Add LRU eviction
0da6724 feature/lru-cache@{1}: commit: Normalize the model name in the key
d7b7ce8 feature/lru-cache@{2}: commit: Add cache key builder
869b750 feature/lru-cache@{3}: branch: Created from HEAD
```
<!-- /snippet -->

Everything Asha said is confirmed, and the branch's reflog has no trace of the last hour. During a rebase `HEAD` is detached: the work happens on `HEAD`, and the branch is moved only at the end. An aborted rebase never touches the branch. So the work is in the HEAD reflog:

<!-- snippet: ex2/solve-m12-embedcache/02-head-reflog -->
```text
$ git reflog -6
c5bdfe4 HEAD@{0}: rebase (abort): returning to refs/heads/feature/lru-cache
54807b6 HEAD@{1}: commit: Add cache key test
12cdcbf HEAD@{2}: commit (amend): Add cache key builder
d7b7ce8 HEAD@{3}: rebase: fast-forward
869b750 HEAD@{4}: rebase (start): checkout main
c5bdfe4 HEAD@{5}: commit: Add LRU eviction
```
<!-- /snippet -->

Read it from the bottom: the rebase started, stopped at the first commit, she amended it (`commit (amend)`), added a commit (`commit: Add cache key test`), and the abort returned to the branch. `HEAD@{1}` is the last state of her work. Anchor it:

<!-- snippet: ex2/solve-m12-embedcache/03-anchor -->
```text
$ git branch rescue 'HEAD@{1}'
$ git log --oneline main..rescue
54807b6 Add cache key test
12cdcbf Add cache key builder
$ git show --stat --format="%h %s" rescue
54807b6 Add cache key test

 tests/test_key.py | 15 +++++++++++++++
 1 file changed, 15 insertions(+)
$ git show rescue:embedcache/key.py
from embedcache.digest import digest

KEY_VERSION = "v2"


def key(model, text):
    return KEY_VERSION + ":" + model + ":" + digest(text)
```
<!-- /snippet -->

`rescue` holds the improved key builder and the test. What is missing are the two commits that the rebase had not replayed yet. Replay them onto `rescue`:

<!-- snippet: ex2/solve-m12-embedcache/04-replay -->
```text
$ git rebase --onto rescue feature/lru-cache~2 feature/lru-cache
Rebasing (1/2)
Auto-merging embedcache/key.py
CONFLICT (content): Merge conflict in embedcache/key.py
error: could not apply 0da6724... Normalize the model name in the key
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
hint: Disable this message with "git config set advice.mergeConflict false"
Could not apply 0da6724... # Normalize the model name in the key
[exit status: 1]
$ git status -sb
## HEAD (no branch)
UU embedcache/key.py
$ git diff
diff --cc embedcache/key.py
index d5a6f79,3456279..0000000
--- a/embedcache/key.py
+++ b/embedcache/key.py
@@@ -1,7 -1,5 +1,11 @@@
  from embedcache.digest import digest
  
 +KEY_VERSION = "v2"
 +
  
  def key(model, text):
++<<<<<<< HEAD
 +    return KEY_VERSION + ":" + model + ":" + digest(text)
++=======
+     return model.lower() + ":" + digest(text)
++>>>>>>> 0da6724 (Normalize the model name in the key)
```
<!-- /snippet -->

This is the conflict she met. In a rebase, "ours" (`HEAD`) is the new base, here her improved key builder, and "theirs" is the commit being replayed, the normalization. Both changed the `return` line. She told you the intended result: both changes.

<!-- snippet: ex2/solve-m12-embedcache/05-resolve -->
```text
# edit embedcache/key.py: keep the version prefix and the lower-cased model name
$ cat embedcache/key.py
from embedcache.digest import digest

KEY_VERSION = "v2"


def key(model, text):
    return KEY_VERSION + ":" + model.lower() + ":" + digest(text)
$ git add embedcache/key.py
$ git rebase --continue
[detached HEAD e8eda57] Normalize the model name in the key
 Author: Asha Rao <asha@example.com>
 1 file changed, 1 insertion(+), 1 deletion(-)
Rebasing (2/2)
Successfully rebased and updated refs/heads/feature/lru-cache.
```
<!-- /snippet -->

<!-- snippet: ex2/solve-m12-embedcache/06-verify -->
```text
$ git log --graph --oneline --all
* d953a57 Add LRU eviction
* e8eda57 Normalize the model name in the key
* 54807b6 Add cache key test
* 12cdcbf Add cache key builder
* 869b750 Add README
* aa632b9 Add text digest
$ python3 -B -m unittest tests/test_key.py 2>&1 | tail -1
OK
$ git range-diff 'feature/lru-cache@{1}~2..feature/lru-cache@{1}' rescue..HEAD
1:  0da6724 < -:  ------- Normalize the model name in the key
-:  ------- > 1:  e8eda57 Normalize the model name in the key
2:  c5bdfe4 = 2:  d953a57 Add LRU eviction
$ git branch -D rescue
Deleted branch rescue (was 54807b6).
$ git status -sb
## feature/lru-cache
$ cd ..
$ exercises/gen/m12-embedcache/check.sh
Checking exercise m12-embedcache
  ok    the commit "Add cache key builder" is on feature/lru-cache exactly once
  ok    the commit "Add cache key test" is on feature/lru-cache exactly once
  ok    the commit "Normalize the model name in the key" is on feature/lru-cache exactly once
  ok    the commit "Add LRU eviction" is on feature/lru-cache exactly once
  ok    the branch has exactly four commits on top of main
  ok    the key builder commit itself has the version prefix
  ok    the final key has the version prefix and the lower-cased model name
  ok    no conflict marker is left in the key module
  ok    the test file is back
  ok    the LRU module is still there
  ok    HEAD is on the branch
  ok    the working tree is clean
  ok    no operation is left in progress
PASS: exercise m12-embedcache is complete.
[exit status: 0]
```
<!-- /snippet -->

Four commits on `main`, the test passes, and `git range-diff` shows what the replay did to the two old commits: the LRU commit is unchanged (`=`), the normalization commit was replaced by a resolved version.

**What to tell Asha.** The work was committed, so it was never in danger: `git commit` during the rebase created objects, and the HEAD reflog recorded each one. `git log` shows what the current branch reaches, and the abort put the branch back where it was. `git stash list` shows stashes, and she made none. `git status` was clean because `--abort` restores the working tree of the original branch.

**Reasoning.** Commits made in detached HEAD are held by the HEAD reflog only. `git rebase --abort` is designed to return to the starting point and does so; it does not delete what was committed on the way. The repair is the general one: find the entry, anchor it, finish the operation with the anchor as the new base.

**Common mistakes.** Looking only at the branch's reflog and concluding that nothing was recorded. Anchoring `HEAD@{2}`, the amended commit, and losing the test commit. Running a new `git rebase -i main` from scratch and redoing the hour. Resolving the conflict with `--ours` or `--theirs` for the whole file. `git rebase --onto rescue main`, which would replay all three old commits, including the old key builder, onto the new one.

**Expert approach.** `git rebase --onto rescue feature/lru-cache~2 feature/lru-cache` says exactly what is wanted: the last two commits of the branch, onto the rescued work. Before `--continue`, run the test. Afterwards compare with `git range-diff`, delete the anchor. For next time: `git rebase --abort` is the right command when you want the starting point back; when you want to keep the work done so far and stop, `git branch <name>` first.

**Reference.** Chapter 13, sections 13.3, 13.7 and 13.8 (a wrong rebase; lost work in detached HEAD). Chapter 9, section 9.4 (what rebase does internally: detached `HEAD`, the branch moves at the end), section 9.11 (who is "ours" in a rebase), section 9.5 (`--onto`) and section 9.16.

### Exercise 12.11

**Solution.** Inventory first, and nothing that changes a repository. Ravi's clone:

<!-- snippet: ex2/solve-m12-feedbackloop/01-ravi -->
```text
$ git -C ravi branch -a
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
$ git -C ravi reflog | wc -l
       0
$ git -C ravi fsck --lost-found
$ git -C ravi count-objects -v | grep -E "^(count|in-pack|packs)"
count: 0
in-pack: 7
packs: 1
$ git -C ravi ls-remote origin
8f18dd9031e1e10d80e3bd032c5c5250be774cb4	HEAD
8f18dd9031e1e10d80e3bd032c5c5250be774cb4	refs/heads/main
```
<!-- /snippet -->

No branch, an empty reflog, nothing for `git fsck` to find, seven objects in one pack: the history of `main`. His account of the cleanup is accurate, and his clone holds nothing. The server has only `main`. The other two clones:

<!-- snippet: ex2/solve-m12-feedbackloop/02-inventory -->
```text
$ git -C asha branch -r -v
  origin/HEAD                    -> origin/main
  origin/feature/dedupe-feedback f20d710 Drop duplicate feedback by fingerprint
  origin/main                    8f18dd9 Add README
$ git -C you branch -r -v
  origin/HEAD                    -> origin/main
  origin/feature/dedupe-feedback a40ff16 Count dropped duplicates
  origin/main                    8f18dd9 Add README
$ ls asha/inbox
0001-Skip-feedback-older-than-the-retention-window.patch
```
<!-- /snippet -->

Two statements fall here. Asha has two commits, not "all of it": her remote-tracking branch is where the server's branch was when she fetched. Your clone has four commits, so the server had four on Wednesday: Ravi pushed more than "once, early, the first two commits". A remote-tracking branch is a record of a past state of the server, and for a branch that the server has deleted it is the only record left.

Before anything talks to the server from your clone, read its configuration:

<!-- snippet: ex2/solve-m12-feedbackloop/03-trap -->
```text
$ git -C you config list --local | grep -E "^(fetch|remote)"
remote.origin.url=../server.git
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
fetch.prune=true
$ git -C you fetch --dry-run
From ../server
 - [deleted]         (none)     -> origin/feature/dedupe-feedback
```
<!-- /snippet -->

`fetch.prune=true`. A plain `git fetch` in your clone would delete `origin/feature/dedupe-feedback`, because the server no longer has the branch; `--dry-run` shows it without doing it. The ref's reflog would go with it. So the first change you make is a local branch, which no fetch touches:

<!-- snippet: ex2/solve-m12-feedbackloop/04-anchor -->
```text
$ git -C you branch rescue/dedupe-feedback origin/feature/dedupe-feedback
branch 'rescue/dedupe-feedback' set up to track 'origin/feature/dedupe-feedback'.
$ git -C you log --oneline main..rescue/dedupe-feedback
a40ff16 Count dropped duplicates
1c9635f Keep the newest of two duplicates
f20d710 Drop duplicate feedback by fingerprint
5e3e197 Add feedback fingerprint
$ git -C asha log --oneline main..origin/feature/dedupe-feedback
f20d710 Drop duplicate feedback by fingerprint
5e3e197 Add feedback fingerprint
```
<!-- /snippet -->

Four of the five commits are safe, as the original objects. The fifth exists nowhere as a commit. Asha's inbox has it as a patch:

<!-- snippet: ex2/solve-m12-feedbackloop/05-patch -->
```text
$ sed -n 1,4p asha/inbox/0001-Skip-feedback-older-than-the-retention-window.patch
From bea33e406c109855ca31b58dbb4036b31fa974a8 Mon Sep 17 00:00:00 2001
From: Ravi Menon <ravi@example.com>
Date: Mon, 7 Sep 2026 10:25:00 +0530
Subject: [PATCH] Skip feedback older than the retention window
$ git -C you apply --stat ../asha/inbox/0001-Skip-feedback-older-than-the-retention-window.patch
 feedbackloop/retention.py |    5 +++++
 1 file changed, 5 insertions(+)
```
<!-- /snippet -->

A file written by `git format-patch`: the first line carries the ID the commit had, then author, author date, subject, and the diff. Rebuild the branch in Ravi's clone: fetch the four commits from your clone, apply the patch with `git am`.

<!-- snippet: ex2/solve-m12-feedbackloop/06-rebuild -->
```text
$ cd ravi
$ git fetch ../you rescue/dedupe-feedback:feature/dedupe-feedback
From ../you
 * [new branch]      rescue/dedupe-feedback -> feature/dedupe-feedback
$ git switch feature/dedupe-feedback
Switched to branch 'feature/dedupe-feedback'
$ git am ../asha/inbox/0001-Skip-feedback-older-than-the-retention-window.patch
Applying: Skip feedback older than the retention window
$ git log --format='%h  author %an  committer %cn  %s' main..HEAD
102ba07  author Ravi Menon  committer Ravi Menon  Skip feedback older than the retention window
a40ff16  author Ravi Menon  committer Ravi Menon  Count dropped duplicates
1c9635f  author Ravi Menon  committer Ravi Menon  Keep the newest of two duplicates
f20d710  author Ravi Menon  committer Ravi Menon  Drop duplicate feedback by fingerprint
5e3e197  author Ravi Menon  committer Ravi Menon  Add feedback fingerprint
```
<!-- /snippet -->

<!-- snippet: ex2/solve-m12-feedbackloop/07-what-is-new -->
```text
$ git cat-file -t bea33e4
fatal: Not a valid object name bea33e4
$ git log -1 --format='%H%n author date    %ad%n' HEAD
102ba0706da462ecf1621e4b1fb1baeb9d69df01
 author date    Mon Sep 7 10:25:00 2026 +0530
```
<!-- /snippet -->

The original fifth commit, the ID in the patch's first line, does not exist in any repository. The commit that `git am` created has the same author, author date, message and change, and a new ID, because the committer date is the moment of `git am`. Your ID will differ from the one in this transcript for the same reason.

<!-- snippet: ex2/solve-m12-feedbackloop/08-publish -->
```text
$ git push -u origin feature/dedupe-feedback
To ../server.git
 * [new branch]      feature/dedupe-feedback -> feature/dedupe-feedback
branch 'feature/dedupe-feedback' set up to track 'origin/feature/dedupe-feedback'.
$ git -C ../you branch -D rescue/dedupe-feedback
Deleted branch rescue/dedupe-feedback (was a40ff16).
$ git -C ../you fetch
From ../server
   a40ff16..102ba07  feature/dedupe-feedback -> origin/feature/dedupe-feedback
$ git -C ../you branch -r
  origin/HEAD -> origin/main
  origin/feature/dedupe-feedback
  origin/main
$ cd ..
$ exercises/gen/m12-feedbackloop/check.sh
Checking exercise m12-feedbackloop
  ok    "Add feedback fingerprint" is commit number 1 of the branch
  ok      and it is the original commit object, not a copy
  ok    "Drop duplicate feedback by fingerprint" is commit number 2 of the branch
  ok      and it is the original commit object, not a copy
  ok    "Keep the newest of two duplicates" is commit number 3 of the branch
  ok      and it is the original commit object, not a copy
  ok    "Count dropped duplicates" is commit number 4 of the branch
  ok      and it is the original commit object, not a copy
  ok    the fifth commit is the one from the mailed patch
  ok      with Ravi as its author
  ok      and its original author date
  ok    the branch has exactly five commits on top of main
  ok    the retention module is in the tree
  ok    the server has the branch again, at the same commit
  ok    no operation is left in progress in Ravi's clone
PASS: exercise m12-feedbackloop is complete.
[exit status: 0]
```
<!-- /snippet -->

After the push, a fetch in your clone is harmless: the server has the branch again.

**The statement for Ravi.**

- Recovered as original objects: commits 1 to 4, from the remote-tracking branch `origin/feature/dedupe-feedback` in my clone, which recorded the server's state at my last fetch. Asha's clone held commits 1 and 2 in the same way.
- Recovered as a copy: commit 5, from the patch you mailed to Asha. Same content, author and author date; a new commit ID, because a commit's ID covers the committer date and the original object is gone from every repository.
- Not recoverable: anything you had not committed, and the original object of commit 5. Your own clone could not help: `git reflog expire --expire=now --all` removed every reflog entry, and `git gc --prune=now` then deleted every object that no ref reached. The server could not help: it stores no reflog for a deleted branch that a client can ask for.
- Two statements were wrong: you pushed twice (the server had four commits), and Asha did not have all of it (she had two).

**Reasoning.** Every clone is a full repository with its own refs. A branch deleted "everywhere" by its owner is deleted in two places, his clone and the server; every other clone that fetched it keeps its remote-tracking branch until it prunes. The recovery is a search through other people's stale state, which is why the first rule is to change nothing: the most valuable copy here was one `git fetch` away from deletion by a configuration setting nobody mentioned.

**Common mistakes.** Running `git fetch` or `git pull` in your clone "to see what the server has" (with `fetch.prune` that deletes the best copy; `git fsck --lost-found` in your clone would still find the commits afterwards, as a dangling commit, until the next pruning). Using `git ls-remote` on the server and stopping at "it is gone". Taking Asha's copy because she offered it. Cherry-picking the four commits into Ravi's clone instead of fetching them: that creates four copies with new IDs where the originals were available. Applying the patch with `git apply`, which makes no commit and loses author, date and message. Running commands inside `server.git`.

**Expert approach.** `git for-each-ref` and `git config list --local` in every clone before any command that writes. Anchor with a local branch. Prefer original objects (fetch from a clone) over copies (cherry-pick, `am`), and say in the report which is which. Prevention: the cleanup pair of commands is the 🔴 point of no return of Chapter 13 and has no place in a "free disk space" routine; delete a branch after checking `git branch --merged` or `git cherry`, not a pull request title.

**Reference.** Chapter 13, section 13.10 (recovering from the remote side: remote-tracking branches and other clones), section 13.12 (what cannot be recovered, and why), section 13.13 (the point of no return) and section 13.15 (what a server adds). Pruning: Chapter 12, section 12.11. `git format-patch` and `git am`: Chapter 14D, section 14D.11.

### Exercise 12.12

**Solution.** Three commands, three different errors, and one fact: `HEAD` is intact and `main` is readable.

<!-- snippet: ex2/solve-m12-tracehub/01-symptoms -->
```text
$ git status
fatal: .git/index: index file smaller than expected
[exit status: 128]
$ git log --oneline -3
fatal: your current branch appears to be broken
[exit status: 128]
$ git branch -vv
fatal: failed to resolve HEAD as a valid ref
[exit status: 128]
```
<!-- /snippet -->

<!-- snippet: ex2/solve-m12-tracehub/01-first-look -->
```text
$ cat .git/HEAD
ref: refs/heads/feature/sampling
$ git log --oneline -2 main
6de4165 Add JSON lines export
ebcc263 Always keep traces with errors
```
<!-- /snippet -->

**Step 0: a copy.** Every repair below writes into `.git`. A copy of the whole directory makes each of them reversible, and it is the answer to request 1:

<!-- snippet: ex2/solve-m12-tracehub/02-copy-first -->
```text
$ cp -R ../you ../you.before-repair
```
<!-- /snippet -->

**The branch file.** "Your current branch appears to be broken": `HEAD` names `refs/heads/feature/sampling`, and that file cannot be read as a ref.

<!-- snippet: ex2/solve-m12-tracehub/03-the-branch-file -->
```text
$ wc -c < .git/refs/heads/feature/sampling
       0
$ tail -2 .git/logs/refs/heads/feature/sampling
6de416530cd1a158d4d12d7112e45da3a23afd33 69d8523122e1e1b79b66bf40a774811688bf60ee Lab User <you@example.com> 1788756060 +0530	commit: Add per-tenant sampling rates
69d8523122e1e1b79b66bf40a774811688bf60ee 047e8d94338d20ec9ceba62a4044b6245182c617 Lab User <you@example.com> 1788756120 +0530	commit: Sample traces by tenant
$ git cat-file -t 047e8d9
error: object file .git/objects/04/7e8d94338d20ec9ceba62a4044b6245182c617 is empty
fatal: git cat-file: could not get object info
[exit status: 128]
$ git cat-file -t 69d8523
commit
```
<!-- /snippet -->

The file is empty. The branch's reflog is intact, and its last line says what the file should contain: `047e8d9`, written by "commit: Sample traces by tenant". That object is an empty file too. The line before it names `69d8523`, which is readable. So the last commit was being written when the power went: the reflog line made it to disk, the object and the ref did not.

<!-- snippet: ex2/solve-m12-tracehub/04-repair-the-ref -->
```text
$ git update-ref refs/heads/feature/sampling 69d8523
fatal: update_ref failed for ref 'refs/heads/feature/sampling': cannot lock ref 'refs/heads/feature/sampling': unable to resolve reference 'refs/heads/feature/sampling': reference broken
[exit status: 128]
$ mv .git/refs/heads/feature/sampling ../branch-file.damaged
$ git update-ref -m 'repair: last readable commit from the reflog' refs/heads/feature/sampling 69d8523
$ git log --oneline -3
69d8523 Add per-tenant sampling rates
6de4165 Add JSON lines export
ebcc263 Always keep traces with errors
```
<!-- /snippet -->

`git update-ref` refuses to work on a broken ref, so the empty file is moved out of the repository first (moved, not deleted: it is evidence). The branch now points at the first unpushed commit, and `git log` works.

**The index.**

<!-- snippet: ex2/solve-m12-tracehub/05-repair-the-index -->
```text
$ wc -c < .git/index
      20
$ mv .git/index ../index.damaged
$ git reset
Unstaged changes after reset:
M	tracehub/sampler.py
$ git status -sb
## feature/sampling
 M tracehub/sampler.py
```
<!-- /snippet -->

Twenty bytes are not an index. The index is derived data: `git reset` rebuilds it from `HEAD`. And then `git status` shows the important thing: `tracehub/sampler.py` is modified. The working tree still has the content of the commit that was lost.

**What else?** Now that Git runs, ask it:

<!-- snippet: ex2/solve-m12-tracehub/06-fsck -->
```text
$ git fsck
error: object file .git/objects/04/7e8d94338d20ec9ceba62a4044b6245182c617 is empty
error: unable to mmap .git/objects/04/7e8d94338d20ec9ceba62a4044b6245182c617: No such file or directory
error: 047e8d94338d20ec9ceba62a4044b6245182c617: object corrupt or missing: .git/objects/04/7e8d94338d20ec9ceba62a4044b6245182c617
error: inflate: data stream error (incorrect header check)
error: unable to unpack header of .git/objects/07/301094b65aa0273ae2ea13cd6a8d32f903fdea
error: 07301094b65aa0273ae2ea13cd6a8d32f903fdea: object corrupt or missing: .git/objects/07/301094b65aa0273ae2ea13cd6a8d32f903fdea
error: HEAD: invalid reflog entry 047e8d94338d20ec9ceba62a4044b6245182c617
error: refs/heads/feature/sampling: invalid reflog entry 047e8d94338d20ec9ceba62a4044b6245182c617
missing blob 07301094b65aa0273ae2ea13cd6a8d32f903fdea
dangling tree 17aab42288899a64faffa322c6e4f4a1b309e9fe
[exit status: 3]
```
<!-- /snippet -->

Two damaged objects and one dangling tree. Asha's advice calls the dangling tree the corruption. It is the opposite: a healthy object that nothing refers to, because the commit that would have referred to it was never completed.

**The old blob.** `0730109` is unreadable and belongs to history that was pushed long ago:

<!-- snippet: ex2/solve-m12-tracehub/07-refetch -->
```text
$ git rev-list --objects --all | grep ^0730109
07301094b65aa0273ae2ea13cd6a8d32f903fdea tracehub/sampler.py
$ git ls-tree -r main~2 | grep 0730109
100644 blob 07301094b65aa0273ae2ea13cd6a8d32f903fdea	tracehub/sampler.py
$ mv .git/objects/07/301094b65aa0273ae2ea13cd6a8d32f903fdea ../blob.damaged
$ git fetch --refetch origin
$ git cat-file -t 0730109
blob
```
<!-- /snippet -->

It is the first version of `tracehub/sampler.py`, in the root commit of `main`. The server has it. A normal fetch would not send it, because your refs say that you have everything; `git fetch --refetch` downloads all objects as a fresh clone would. The damaged file has to be moved away first, since Git does not overwrite an object file that exists.

**The lost commit.** Move the empty object file away, stage the working tree, and write a tree from the index:

<!-- snippet: ex2/solve-m12-tracehub/08-the-lost-commit -->
```text
$ mv .git/objects/04/7e8d94338d20ec9ceba62a4044b6245182c617 ../commit.damaged
$ git add -A
$ git write-tree
17aab42288899a64faffa322c6e4f4a1b309e9fe
$ git fsck 2>/dev/null | grep dangling
```
<!-- /snippet -->

`git write-tree` prints `17aab42`: the ID of the dangling tree that `git fsck` reported in step 06. The working tree is, bit for bit, the tree of the commit you were making. (The last command prints nothing because the index now refers to that tree, so it is no longer dangling.)

A plain `git commit -m 'Sample traces by tenant'` would finish the job with a new commit ID. The stronger answer rebuilds the commit that was lost. A commit's ID is the hash of its tree, parent, author, committer, both dates and the message. The reflog line has all of that: the parent (`69d8523`), the identity, the timestamp `1788756120 +0530`, and the subject. The tree is `17aab42`.

<!-- snippet: ex2/solve-m12-tracehub/09-rebuild-the-commit -->
```text
$ GIT_AUTHOR_DATE='1788756120 +0530' GIT_COMMITTER_DATE='1788756120 +0530' git commit-tree 17aab42 -p 69d8523 -m 'Sample traces by tenant'
047e8d94338d20ec9ceba62a4044b6245182c617
$ git reset --soft 047e8d9
$ git status -sb
## feature/sampling
```
<!-- /snippet -->

`git commit-tree` prints `047e8d9`, the ID from the reflog. The object is the original commit, rebuilt from its parts. `git reset --soft` moves the branch to it; the index already matches.

<!-- snippet: ex2/solve-m12-tracehub/10-verify -->
```text
$ git fsck
[exit status: 0]
$ git log --graph --oneline --all
* 047e8d9 Sample traces by tenant
* 69d8523 Add per-tenant sampling rates
* 6de4165 Add JSON lines export
* ebcc263 Always keep traces with errors
* f24e014 Add trace sampler
$ git reflog -4
047e8d9 HEAD@{0}: reset: moving to 047e8d9
69d8523 HEAD@{1}: reset: moving to HEAD
69d8523 HEAD@{2}: repair: last readable commit from the reflog
047e8d9 HEAD@{3}: commit: Sample traces by tenant
$ cd ..
$ exercises/gen/m12-tracehub/check.sh
Checking exercise m12-tracehub
  ok    git fsck reports no error (exit status 0)
  ok    HEAD is on feature/sampling
  ok    the branch has its two unpushed commits on top of main
  ok    the first of them is "Add per-tenant sampling rates"
  ok    the second is "Sample traces by tenant"
  ok    its sampler uses the per-tenant rate
  ok    the index is readable and the working tree is clean
  ok    the oldest version of the sampler can be read again
  ok    main is where the server has it
  ok    the first unpushed commit is the original object, not a copy made after a new clone
PASS: exercise m12-tracehub is complete.
[exit status: 0]
```
<!-- /snippet -->

`git fsck` is silent and exits with 0. The reflog entries that named the lost commit are valid again, which they would not be had the commit been recreated under a new ID.

**The list.**

| Damaged | What it was | Source of the repair |
|---|---|---|
| `.git/refs/heads/feature/sampling` (empty) | the branch | the branch's reflog, `.git/logs/refs/heads/feature/sampling` |
| `.git/index` (20 bytes) | the staging area | rebuilt from `HEAD` with `git reset`; the list of staged paths is lost, and nothing was staged beyond the commit in progress |
| object `047e8d9` (empty) | the commit in progress | tree from the working tree (confirmed by the dangling tree), everything else from the reflog line |
| object `0730109` (garbage) | an old, pushed blob | the server, `git fetch --refetch` |

Ravi's advice (delete and clone) would have cost both unpushed commits: the server has neither. Asha's advice (`git prune` what is dangling) would have deleted the tree of the lost commit; here the working tree could have recreated it, but only if nobody had touched it since.

**Reasoning.** A crash during `git commit` can interrupt the writes at any point between the objects, the ref and the reflog. Each of these files has a different source of truth: objects are named by their content, so they can be rebuilt or fetched from anywhere; a ref is recorded in its reflog; the index is derived from a commit and the working tree. The method is to repair in the order in which Git needs things (ref, index), let `git fsck` list the rest, and choose for each object the source that has the same bytes.

**Common mistakes.** Starting without a copy. Deleting the repository. Deleting `.git/index` and the empty ref and then typing the wrong ID into the ref file from memory. Stopping when `git status` works: the old blob stays broken until some command needs it, weeks later. Leaving the empty object file in place, after which `git fsck` keeps failing and no command can write the object. Recreating the commit with a new ID and not noticing that `git fsck` still reports invalid reflog entries: then delete those entries with `git reflog delete`, or do what the model answer does. Running `git gc` before the repository is healthy.

**Expert approach.** Copy, then read: `cat .git/HEAD`, the tail of the reflogs, `git fsck`. Decide per object: unpushed means your own working tree, index or reflog; pushed means the server. Prove the result: the tree ID from `git write-tree` against the dangling tree, the commit ID against the reflog, and a silent `git fsck`. Afterwards push the branch: the server is the backup that would have made half of this unnecessary.

**Reference.** Chapter 13, section 13.11 (a damaged repository: a corrupt object, why a fetch does not repair it, `--refetch`, a corrupt index, and unpushed objects rebuilt from the working tree), section 13.6 (dangling is not damage), section 13.3 (the reflog on disk) and section 13.12. The commit object and what its ID covers: Chapter 3, section 3.4 and Chapter 6. `git commit-tree`, `git write-tree`, `git update-ref`: Chapter 2, section 2.6 and Chapter 3, section 3.9. Rebuilding the index: Chapter 5, section 5.15.

---

## Module 13: Tags and versions

### Exercise 13.1

**Solution.**

<!-- snippet: ex2/answers-m13/13-1-two-kinds -->
```text
$ git count-objects
12 objects, 48 kilobytes
$ git tag staging-ok
$ git count-objects
12 objects, 48 kilobytes
$ git tag -a v0.2.0 -m 'quotad 0.2.0' HEAD~1
$ git count-objects
13 objects, 52 kilobytes
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m13/13-1-inspect -->
```text
$ git cat-file -t staging-ok
commit
$ git cat-file -t v0.2.0
tag
$ git cat-file -p v0.2.0
object 473e23ec345678263d4aea03e2aa2d550890dabb
type commit
tag v0.2.0
tagger Lab User <you@example.com> 1788759780 +0530

quotad 0.2.0
$ git for-each-ref refs/tags --format='%(refname:short) %(objecttype) %(objectname:short) -> %(*objectname:short)'
staging-ok commit b13bb46 -> 
v0.2.0 tag daa780b -> 473e23e
```
<!-- /snippet -->

1. `git tag -a` created one object, of type `tag`: the count went from 12 to 13. `git tag staging-ok` created a ref, the file `.git/refs/tags/staging-ok` with a commit ID in it, and no object.
2. `object` (what is tagged), `type` (of that object), `tag` (the name), `tagger` (who, when), and the message. A lightweight tag has none of them: it is a name for a commit and carries no author, date or message of its own.
3. The ID of the object that the tag object points at (the "peeled" value). A lightweight tag is not a tag object, so there is nothing to peel.
4. Annotated tags for releases. `git describe` ignores lightweight tags unless `--tags` is given, and `git push --follow-tags` sends annotated tags only.

**Reasoning.** "Tag" names two mechanisms: a ref under `refs/tags/`, which both kinds have, and a tag object, which only the annotated kind has. The ref of an annotated tag points at the tag object, which points at the commit.

**Common mistakes.** Believing that a lightweight tag is a "light" tag object. Expecting `git cat-file -t` to say `tag` for every tag. Tagging a release with the lightweight form because it is shorter to type.

**Expert approach.** `git for-each-ref refs/tags --format='%(refname:short) %(objecttype)'` audits a repository's tags in one line: every release tag should say `tag`.

**Reference.** Chapter 14B, section 14B.8 (three kinds, two mechanisms; which kind when). Lightweight tags as refs: Chapter 7, section 7.11.

### Exercise 13.2

**Solution.**

<!-- snippet: ex2/answers-m13/13-2-sorting -->
```text
$ git tag
v0.10.0
v0.10.0-rc.1
v0.2.0
v0.9.0
v1.0.0
$ git tag --sort=version:refname
v0.2.0
v0.9.0
v0.10.0
v0.10.0-rc.1
v1.0.0
$ git -c versionsort.suffix=-rc tag --sort=version:refname
v0.2.0
v0.9.0
v0.10.0-rc.1
v0.10.0
v1.0.0
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m13/13-2-questions -->
```text
$ git tag -n1 -l 'v0.1*'
v0.10.0         quotad 0.10.0
v0.10.0-rc.1    quotad 0.10.0, release candidate 1
$ git tag --contains 44c358e
v0.10.0
v1.0.0
$ git tag --merged v0.9.0
v0.2.0
v0.9.0
$ git tag --points-at HEAD
$ git describe
v1.0.0-1-gf5268c2
```
<!-- /snippet -->

1. The default order is by name, as text: `v0.10.0` sorts before `v0.2.0`. `--sort=version:refname` compares the numeric parts as numbers, and still lists the release candidate after its release, because `-rc.1` makes the string longer. With `versionsort.suffix=-rc` the pre-release sorts before the release. The third is the order a release page needs.
2. `--contains <commit>`: which tags have this commit in their history ("which releases include this fix?"). `--merged <commit>`: which tags are in the history of this commit ("which releases came before this one?").
3. No tag points at `HEAD`: the newest commit was made after `v1.0.0`. `git describe` prints the nearest annotated tag, the number of commits since, and the abbreviated ID: `v1.0.0-1-gf5268c2`.

**Reasoning.** Sorting and filtering tags are queries over refs and the graph. None of them changes anything.

**Common mistakes.** Sorting version numbers as text in a release script. Confusing `--contains` with `--merged`. Assuming that tag order reflects creation time: use `--sort=creatordate` for that.

**Expert approach.** Set `versionsort.suffix` once in the configuration of a project that uses pre-releases. To find the latest release, do not parse a sorted list: `git describe --abbrev=0`.

**Reference.** Chapter 14B, section 14B.9 (listing and sorting) and section 14B.12 (`git describe`).

### Exercise 13.3

**Solution.**

<!-- snippet: ex2/answers-m13/13-3-push -->
```text
$ git tag -a v0.3.0 -m 'quotad 0.3.0'
$ git tag tmp/debug HEAD~1
$ git push
To ../server.git
   cf71ca5..4b2ee56  main -> main
$ git ls-remote --tags origin
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m13/13-3-follow -->
```text
$ echo '# Add enterprise tier' >> quota.py && git commit -q -am 'Add enterprise tier'
$ git push --follow-tags
To ../server.git
   4b2ee56..a6338c3  main -> main
 * [new tag]         v0.3.0 -> v0.3.0
$ git ls-remote --tags origin
9a464d10e03946150993e92ec6c5506170b4f5a7	refs/tags/v0.3.0
4b2ee56f324d6eae5f06eba9911046edbb17fce0	refs/tags/v0.3.0^{}
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m13/13-3-single -->
```text
$ git push origin tmp/debug
To ../server.git
 * [new tag]         tmp/debug -> tmp/debug
$ git push origin --delete tmp/debug
To ../server.git
 - [deleted]         tmp/debug
$ git tag -l
tmp/debug
v0.3.0
$ git ls-remote --tags origin
9a464d10e03946150993e92ec6c5506170b4f5a7	refs/tags/v0.3.0
4b2ee56f324d6eae5f06eba9911046edbb17fce0	refs/tags/v0.3.0^{}
```
<!-- /snippet -->

1. The branch. Both tags stayed local: `git push` without arguments does not push tags.
2. The tag is annotated, and it points into the commits that are being pushed or are already on the server. `v0.3.0` met both; `tmp/debug` is lightweight.
3. The peeled value: the commit that the tag object points at. The first line is the ID of the tag object.
4. In your clone, and in every clone that fetched it while it was on the server. Deleting a tag on the server deletes one ref in one repository. The other copies stay, and a later `git push --tags` from any of them brings it back.

**Reasoning.** Tags are refs, and refs move between repositories only when a refspec says so. Fetch creates tags that point into fetched history; push sends none unless asked.

**Common mistakes.** Assuming that the release is published because the commit is. `git push --tags`, which sends every local tag, including temporary ones. Deleting a published release tag: see exercise 13.9.

**Expert approach.** `git push origin <tag>` for one release, or `git push --follow-tags` together with the branch. Keep scratch tags lightweight and local, release tags annotated.

**Reference.** Chapter 14B, section 14B.10 (tags and remotes, `--follow-tags`, deleting).

### Exercise 13.4

**Solution.**

<!-- snippet: ex2/answers-m13/13-4-setup -->
```text
$ git log --oneline --decorate
33a855d (HEAD -> main) Add enterprise tier
33f7ea7 Log rejected requests
548381c (tag: staging-ok) Fix burst allowance for the free tier
b010f6b Add burst allowance
39edcf9 (tag: v1.0.0) Add daily reset
c331837 Add quota table
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m13/13-4-describe -->
```text
$ git describe
v1.0.0-4-g33a855d
$ git describe --tags
staging-ok-2-g33a855d
$ git describe --abbrev=0
v1.0.0
$ git describe --long v1.0.0
v1.0.0-0-g39edcf9
$ git describe HEAD~4
v1.0.0
$ git describe --exact-match
fatal: no tag exactly matches '33a855d5b3c1a0e69391805c44985eff21b8d968'
[exit status: 128]
$ git describe HEAD~5
fatal: No tags can describe 'c331837307cca95cd25113e040cd46d6b38358c9'.
Try --always, or create some tags.
[exit status: 128]
$ git describe --always HEAD~5
c331837
```
<!-- /snippet -->

- `git describe`: the nearest annotated tag is `v1.0.0`, four commits back. The lightweight `staging-ok`, two commits back, is ignored.
- `--tags` allows lightweight tags, so the nearest is `staging-ok`.
- `--abbrev=0` prints the tag name only.
- `--long` forces the full form even for a tagged commit: zero commits since the tag.
- `HEAD~4` is the tagged commit: the tag name alone.
- `--exact-match` fails, because no tag points at `HEAD`.
- `HEAD~5` is the root commit, older than every tag: there is no tag in its history, so it cannot be described. `--always` falls back to the abbreviated ID.

**Reasoning.** `git describe` walks backwards from the commit to the nearest tag that it is allowed to use. The output encodes the tag, the distance, and the commit. A tag that is not an ancestor does not count, however close it looks in the log.

**Common mistakes.** Expecting `staging-ok` in the plain output. Reading the number as "commits since the last release on any branch". Expecting `git describe HEAD~5` to print `v1.0.0` with a negative distance.

**Expert approach.** In a build script: `git describe --match 'v[0-9]*' --dirty`, and decide deliberately between `--always` and failing the build.

**Reference.** Chapter 14B, section 14B.12 (`git describe`, its options, the three ways it fails).

### Exercise 13.5

**Solution.**

<!-- snippet: ex2/answers-m13/13-5-resolve -->
```text
$ git cat-file -t v1.0.0
tag
$ git cat-file -t staging-ok
commit
$ git rev-parse v1.0.0
be8f56b11518a5907fd7f815c5bb7fb5506ad17d
$ git rev-parse 'v1.0.0^{}'
39edcf9e12be45d5982167c77312c77abd14d6a6
$ git rev-parse staging-ok HEAD~2
548381cc0ebf33db3ff65dbfd5da1120fd38442c
548381cc0ebf33db3ff65dbfd5da1120fd38442c
$ git show-ref --tags --dereference
548381cc0ebf33db3ff65dbfd5da1120fd38442c refs/tags/staging-ok
be8f56b11518a5907fd7f815c5bb7fb5506ad17d refs/tags/v1.0.0
39edcf9e12be45d5982167c77312c77abd14d6a6 refs/tags/v1.0.0^{}
```
<!-- /snippet -->

`v1.0.0` resolves to a tag object, `be8f56b`; `v1.0.0^{}` peels it to the commit `39edcf9`, which the log of exercise 13.4 shows as the tagged commit. `staging-ok` resolves directly to a commit, the same ID as `HEAD~2`. `git show-ref --dereference` prints three lines: one per ref, plus a `^{}` line for each ref that points at a tag object. Two refs, one of them annotated: three lines.

**Reasoning.** A name resolves to whatever the ref contains. For an annotated tag that is the tag object; commands that need a commit peel it without telling you, which is why `git log v1.0.0` works. The difference matters when you compare IDs: `git rev-parse v1.0.0` is not the commit ID.

**Common mistakes.** Comparing `git rev-parse v1.0.0` with a commit ID from the log in a script and concluding that the tag is wrong. Expecting four lines, or two.

**Expert approach.** In scripts always peel: `git rev-parse 'v1.0.0^{commit}'`. It gives the commit for both kinds of tag and fails for a tag that points at something else.

**Reference.** Chapter 14B, section 14B.8 (`^{}`, `^{commit}`, `git show-ref --dereference`). Chapter 3, section 3.6.

### Exercise 13.6

**Solution.**

<!-- snippet: ex2/answers-m13/13-6-commands -->
```text
$ git log --oneline --decorate
3869c28 (HEAD -> main) Add enterprise tier
9a6ab4d Fix negative usage after a refund
fa007b3 Add burst allowance
ffc7632 (tag: v1.0.0) Add quota table
$ git switch -c release/1.0 v1.0.0
Switched to a new branch 'release/1.0'
$ git cherry-pick -x 9a6ab4d
[release/1.0 102d003] Fix negative usage after a refund
 Date: Mon Sep 7 10:40:00 2026 +0530
 1 file changed, 2 insertions(+)
 create mode 100644 refund.py
$ git tag -a v1.0.1 -m 'quotad 1.0.1: fix negative usage after a refund'
$ git switch main
Switched to branch 'main'
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m13/13-6-graph -->
```text
$ git log --graph --oneline --decorate --all
* 102d003 (tag: v1.0.1, release/1.0) Fix negative usage after a refund
| * 3869c28 (HEAD -> main) Add enterprise tier
| * 9a6ab4d Fix negative usage after a refund
| * fa007b3 Add burst allowance
|/  
* ffc7632 (tag: v1.0.0) Add quota table
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m13/13-6-describe -->
```text
$ git describe main
v1.0.0-3-g3869c28
$ git describe release/1.0
v1.0.1
$ git tag --contains 9a6ab4d
$ git log -1 --format=%b v1.0.1
(cherry picked from commit 9a6ab4df160e3543d9caeaa690f23e614d471a9d)
```
<!-- /snippet -->

`git describe main` counts three commits since `v1.0.0`: `v1.0.1` is not an ancestor of `main` and plays no part. `git describe release/1.0` is the tag itself. `git tag --contains` for the fix commit on `main` prints nothing.

For the support engineer: the fix exists as two commits. The original on `main`, `9a6ab4d`, is in no release yet; it will be in the next release cut from `main`. Its copy `102d003` is in `v1.0.1`. The link between the two is the line `(cherry picked from commit ...)` that `-x` wrote into the copy's message. So "which release contains the fix" has the answer "1.0.1, and every release from `main` after today", and `git tag --contains` gives the first half only when it is asked about the copy.

**Reasoning.** A cherry-pick creates a new commit. Reachability queries work on commits, not on changes, so a backported fix is invisible to `--contains` unless you ask about each copy.

**Common mistakes.** Creating the branch from `main` instead of from the tag. Merging `main` into the release branch. Omitting `-x`. Tagging `v1.0.1` with the lightweight form. Expecting `git describe main` to mention `v1.0.1`.

**Expert approach.** To find every copy of a fix: `git log --all --grep='cherry picked from commit <id>'` together with `git tag --contains` on each hit, or `git log --oneline --cherry-mark --left-right release/1.0...main`.

**Reference.** Chapter 14B, section 14B.14 (release branches on the Git side), section 14B.12 and section 14B.13 (Semantic Versioning: a patch release). Chapter 10, section 10.9 (backport with `-x`).

### Exercise 13.7

**Solution.**

<!-- snippet: ex2/answers-m13/13-7-symptom -->
```text
$ git -C dev log --oneline --decorate -3
f35137a (HEAD -> main, origin/main) Add enterprise tier
b3be5be (tag: v1.1.0) Log rejected requests
64384c2 Add burst allowance
$ git -C dev tag
v1.0.0
v1.1.0
$ (cd dev && scripts/version.sh)
v1.0.0-4-gf35137a
$ (cd ci && scripts/version.sh)
v1.0.0-4-gf35137a
```
<!-- /snippet -->

The tag exists in both clones, on the right commit, and the script still reports `v1.0.0-4-...`. The script runs `git describe`:

<!-- snippet: ex2/answers-m13/13-7-diagnose -->
```text
$ git -C ci cat-file -t v1.1.0
commit
$ git -C ci cat-file -t v1.0.0
tag
$ git -C ci for-each-ref refs/tags --format='%(refname:short) %(objecttype)'
v1.0.0 tag
v1.1.0 commit
$ git -C ci describe --tags
v1.1.0-1-gf35137a
$ git -C ci describe --tags --match 'v[0-9]*'
v1.1.0-1-gf35137a
```
<!-- /snippet -->

`v1.1.0` is a lightweight tag: `git cat-file -t` says `commit`. `git describe` uses annotated tags only, so it walks past `v1.1.0` to `v1.0.0`. Root cause: the release was tagged with `git tag v1.1.0`, without `-a`.

Two fixes:

| Fix | What changes | Cost |
|---|---|---|
| The script uses `git describe --tags --match 'v[0-9]*'` | one line in the repository | From now on any lightweight tag that matches the pattern defines the version; the tag still has no tagger, date or message, and `--follow-tags` still ignores it |
| Replace the tag by an annotated one on the same commit | the ref `refs/tags/v1.1.0` gets a new value (a tag object) on the server | A published ref changes: every existing clone keeps the old lightweight tag, and `git fetch --tags` reports "would clobber existing tag" until each clone runs `git fetch --tags --force` |

Recommendation for a tag that is already published: change the script now, and make the release tooling create annotated tags from the next release on. Replacing the tag is defensible here only because the commit stays the same, so no clone ever builds other content under the name; it still needs a message to everyone who has the tag. Moving a published tag to another commit is never the fix.

**Reasoning.** The same name, the same commit, and a different kind of tag. Every listing shows the tag; the one command that decides the version skips it by design.

**Common mistakes.** Deleting and re-pushing the tag without telling anyone. Looking for a missing push or a shallow clone: the tag is present. "Fixing" it by tagging the newest commit.

**Expert approach.** Ask for the type before anything else: `git for-each-ref refs/tags --format='%(refname:short) %(objecttype)'`. A check in the release pipeline that refuses a release tag whose type is not `tag` prevents the recurrence.

**Reference.** Chapter 14B, section 14B.8 (which kind when), section 14B.12 (`git describe` ignores lightweight tags; `--tags`, `--match`) and section 14B.11 (why a published tag must not move; "would clobber existing tag").

### Exercise 13.8

**Solution.**

<!-- snippet: ex2/answers-m13/13-8-symptom -->
```text
$ git log --oneline --decorate --all
257376b (v1.0) Fix negative usage after a refund
386caa0 (HEAD -> main, origin/main) Add burst allowance
a6ba8e3 (tag: v1.0) Add daily reset
440023d Add quota table
$ git rev-parse --short v1.0
warning: refname 'v1.0' is ambiguous.
9187f22
$ git push origin v1.0
error: src refspec v1.0 matches more than one
error: failed to push some refs to '../server.git'
[exit status: 1]
$ git switch v1.0
warning: refname 'v1.0' is ambiguous.
Switched to branch 'v1.0'
$ git log --oneline -1
257376b Fix negative usage after a refund
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m13/13-8-diagnose -->
```text
$ git for-each-ref --format='%(refname) %(objecttype)' | grep 'v1.0'
refs/heads/v1.0 commit
refs/tags/v1.0 tag
$ git rev-parse refs/heads/v1.0 'refs/tags/v1.0^{commit}'
257376b6199c69672dcf74bf6a55bb27f3a10e97
a6ba8e36eb4d5b5d5a67bc422a85b0ef1e691400
```
<!-- /snippet -->

Two refs share the short name: the tag `refs/tags/v1.0` and a branch `refs/heads/v1.0`, which someone created at the tag for maintenance work and which has moved on by one commit.

- **The warning.** A short name is looked up in a fixed order, and `refs/tags/` comes before `refs/heads/`. Commands that take a revision use the tag and warn that the name is ambiguous. (`git rev-parse --short v1.0` prints `9187f22`, the tag object.)
- **The push.** A refspec without a prefix must match exactly one ref on the local side. `v1.0` matches two, so Git refuses.
- **The switch.** `git switch` takes a branch name, so it picks the branch, and `git log -1` then shows the maintenance commit, not the release.

The cause is the branch name. Rename it; the tag stays as published:

<!-- snippet: ex2/answers-m13/13-8-fix -->
```text
$ git branch -m v1.0 release/1.0
$ git rev-parse --short v1.0
9187f22
$ git push -u origin release/1.0
To ../server.git
 * [new branch]      release/1.0 -> release/1.0
branch 'release/1.0' set up to track 'origin/release/1.0'.
$ git log --oneline --decorate --all
257376b (HEAD -> release/1.0, origin/release/1.0) Fix negative usage after a refund
386caa0 (origin/main, main) Add burst allowance
a6ba8e3 (tag: v1.0) Add daily reset
440023d Add quota table
```
<!-- /snippet -->

The warning is gone, and `release/1.0` is published under a name that cannot collide with a tag.

**Reasoning.** Git resolves short names by rules that differ between "any revision" and "a branch". When two refs share a short name, different commands silently pick different refs. Only full names (`refs/tags/v1.0`, `refs/heads/v1.0`, or `tags/v1.0`, `heads/v1.0`) are unambiguous.

**Common mistakes.** Deleting the tag to get rid of the warning. `git push origin v1.0:v1.0` with force, hoping it picks the right one. Ignoring the warning: a script that computes a diff "against v1.0" may use the other ref than its author had in mind.

**Expert approach.** `git for-each-ref | grep '/v1.0$'` shows every ref with that short name. Keep the two namespaces disjoint by convention: `vX.Y.Z` for tags, `release/X.Y` for branches.

**Reference.** Chapter 3, section 3.6 (the lookup order for a short name). Chapter 7, section 7.11 and section 7.14 (`refname is ambiguous`: use `heads/` or `tags/`, rename one). Chapter 14B, section 14B.14.

### Exercise 13.9

**Solution.**

<!-- snippet: ex2/solve-m13-modelcard/01-observe -->
```text
$ git log --oneline --decorate
2158ad5 (HEAD -> main, tag: v1.4.0, origin/main, origin/HEAD) Say so when a card has no metrics
5514e9c Put a blank line under the metrics heading
78d9a92 Validate required fields
078cd84 Add README
f4ad137 (tag: v1.3.0) Add Markdown renderer
$ (cd ../ci && scripts/version.sh)
v1.3.0-4-g2158ad5
$ git ls-remote --tags origin
be4b89138d8a2c8f009bd447bcc54c7bb27ebad8	refs/tags/v1.3.0
f4ad137629c93c1170743b3a1545e0604803479b	refs/tags/v1.3.0^{}
2158ad53162b8aa44370e8efee4a9fd9d28ea944	refs/tags/v1.4.0
```
<!-- /snippet -->

The build stamps itself `v1.3.0-4-g2158ad5`, so `git describe` does not see `v1.4.0` although the log shows the tag on the newest commit. And the server lists `v1.4.0` with one line, without a `^{}` line: it is not an annotated tag there.

<!-- snippet: ex2/solve-m13-modelcard/02-what-it-is-now -->
```text
$ git for-each-ref refs/tags --format='%(refname:short) %(objecttype) %(objectname:short) %(taggername)'
v1.3.0 tag be4b891 Lab User
v1.4.0 commit 2158ad5 
$ git cat-file -t v1.4.0
commit
$ git reflog show refs/tags/v1.4.0
```
<!-- /snippet -->

Today `v1.4.0` is a lightweight tag on `2158ad5`, "Say so when a card has no metrics", the commit that was pushed after the release. Tags have no reflog, so the repository does not remember what the ref was before. The object might still exist:

<!-- snippet: ex2/solve-m13-modelcard/03-find-the-original -->
```text
$ git fsck
dangling tag 4d1b7b41982975444b274dfeef0a96b197af14a2
$ git cat-file -p 4d1b7b4
object 5514e9c80d22023e991626f7a6ad3ef08f478e5c
type commit
tag v1.4.0
tagger Asha Rao <asha@example.com> 1788756120 +0530

modelcard 1.4.0

Release checklist signed off by Asha on Monday.
```
<!-- /snippet -->

A dangling tag object: `tag v1.4.0`, tagger Asha Rao, with her sign-off, pointing at `5514e9c`, "Put a blank line under the metrics heading". That is Monday's release. Your clone had the published tag; something replaced the ref (a `git fetch --tags --force`, which is what overwrites local tags), and the object was left behind without a name.

So: someone deleted the published tag on the server and created a lightweight tag of the same name one commit later, to get the fix "into 1.4.0". Both symptoms follow: other bytes under the same name, and a version that `git describe` no longer finds.

Put Monday's object back, locally and on the server:

<!-- snippet: ex2/solve-m13-modelcard/04-restore -->
```text
$ git update-ref refs/tags/v1.4.0 4d1b7b4
$ git cat-file -t v1.4.0
tag
$ git log --oneline --decorate -2
2158ad5 (HEAD -> main, origin/main, origin/HEAD) Say so when a card has no metrics
5514e9c (tag: v1.4.0) Put a blank line under the metrics heading
$ git push origin v1.4.0
To ../server.git
 ! [rejected]        v1.4.0 -> v1.4.0 (already exists)
error: failed to push some refs to '../server.git'
hint: Updates were rejected because the tag already exists in the remote.
[exit status: 1]
$ git push --force origin v1.4.0
To ../server.git
 + 2158ad5...4d1b7b4 v1.4.0 -> v1.4.0 (forced update)
```
<!-- /snippet -->

`git update-ref` writes the ID of the tag object into the ref: the tag is the published object again, not a new tag that resembles it. The server refuses the plain push ("already exists"). Forcing a tag is 🔴 in general. It is right here because it restores the value that was published, and it replaces a value that should never have been there.

The fix that was wrongly labelled 1.4.0 becomes a release of its own:

<!-- snippet: ex2/solve-m13-modelcard/05-release-the-fix -->
```text
$ git tag -a v1.4.1 -m 'modelcard 1.4.1: say so when a card has no metrics' main
$ git push origin v1.4.1
To ../server.git
 * [new tag]         v1.4.1 -> v1.4.1
$ git ls-remote --tags origin
be4b89138d8a2c8f009bd447bcc54c7bb27ebad8	refs/tags/v1.3.0
f4ad137629c93c1170743b3a1545e0604803479b	refs/tags/v1.3.0^{}
4d1b7b41982975444b274dfeef0a96b197af14a2	refs/tags/v1.4.0
5514e9c80d22023e991626f7a6ad3ef08f478e5c	refs/tags/v1.4.0^{}
ca5c9430a0b884e8c59de827fc4b22feab6fa0b9	refs/tags/v1.4.1
2158ad53162b8aa44370e8efee4a9fd9d28ea944	refs/tags/v1.4.1^{}
```
<!-- /snippet -->

Clones that picked up the wrong tag keep it until they are told otherwise:

<!-- snippet: ex2/solve-m13-modelcard/06-other-clones -->
```text
$ cd ../ci
$ git fetch --tags
From ../server
 ! [rejected] v1.4.0     -> v1.4.0  (would clobber existing tag)
 * [new tag] v1.4.1     -> v1.4.1
[exit status: 1]
$ git fetch --tags --force
From ../server
 t [tag update]      v1.4.0     -> v1.4.0
$ scripts/version.sh
v1.4.1
$ git describe v1.4.0
v1.4.0
$ cd ..
$ exercises/gen/m13-modelcard/check.sh
Checking exercise m13-modelcard
  ok    v1.4.0 on the server is an annotated tag again
  ok      it names the commit that was released on Monday
  ok      and it is the published object (tagger Asha Rao)
  ok    your clone has the same v1.4.0 object
  ok    the build clone has the same v1.4.0 object
  ok    v1.4.1 on the server is an annotated tag
  ok      and it names the commit with the fix
  ok    scripts/version.sh in ci/ prints v1.4.1
  ok    v1.3.0 was not touched
PASS: exercise m13-modelcard is complete.
[exit status: 0]
```
<!-- /snippet -->

A plain `git fetch --tags` reports the clash and keeps the local tag; `--force` replaces it. The build clone now stamps `v1.4.1`.

**The two sentences.** The published tag `v1.4.0` was deleted on the server and re-created as a lightweight tag on a later commit, so new clones built other code under the same version and `git describe` stopped recognizing the tag. A server-side rule that forbids updating and deleting tags that match `v*` would have rejected both pushes.

**Reasoning.** A tag is a ref in each repository, and no repository updates an existing tag on its own. Moving a tag on the server therefore creates two things with one name. The repair is to restore the published value and to give new content a new name. The published value is an object, and objects outlive the refs that named them until garbage collection.

**Common mistakes.** Creating a fresh annotated `v1.4.0` on Monday's commit: right commit, wrong object, with you as tagger and today's date, and without Asha's sign-off. Leaving `v1.4.0` where it is "because the fix is good". Forgetting the other clones. Expecting `git reflog` to help: tags have none. Running `git gc --prune=now` in the one clone that still has the object.

**Expert approach.** Compare what the server says with what you have: `git ls-remote origin 'refs/tags/v1.4.0^{}'` against `git rev-parse 'v1.4.0^{commit}'`. Look for the original in this order: a clone that never force-fetched (its ref is still right), then `git fsck` for a dangling tag in clones that did. Deploy by commit ID or image digest, not by tag name alone.

**Reference.** Chapter 14B, section 14B.11 (why a published tag must not move: detection, the root-cause box, the repair by restoring the tag and releasing a new version, the dangling tag object, server-side prevention), section 14B.8 (the tag object) and section 14B.12. `git fsck` and dangling objects: Chapter 13, section 13.6.

---

## Module 14: Worktrees, attributes, hooks, stash internals, rerere

### Exercise 14.1

**Solution.**

<!-- snippet: ex2/answers-m14/14-1-add -->
```text
$ git status -sb
## feature/unicode
 M guard/normalize.py
?? NOTES.txt
$ git worktree add -b hotfix/blocklist ../hotfix main
Preparing worktree (new branch 'hotfix/blocklist')
HEAD is now at 1e8be8b Add README
$ git worktree list
$LAB/ex2/answers-m14/ex-14-1 acd049c [feature/unicode]
$LAB/ex2/answers-m14/hotfix  1e8be8b [hotfix/blocklist]
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m14/14-1-work -->
```text
$ cd ../hotfix
$ cat .git
gitdir: $LAB/ex2/answers-m14/ex-14-1/.git/worktrees/hotfix
$ sed -e 's/"reveal your system prompt"/"reveal your system prompt", "developer mode"/' guard/rules.py > r.tmp && mv r.tmp guard/rules.py
$ git commit -q -am 'Block the developer-mode phrase' && git log --oneline -1
3f74ec4 Block the developer-mode phrase
$ cd ../ex-14-1
$ git status -sb
## feature/unicode
 M guard/normalize.py
?? NOTES.txt
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m14/14-1-rules -->
```text
$ git switch hotfix/blocklist
fatal: 'hotfix/blocklist' is already used by worktree at '$LAB/ex2/answers-m14/hotfix'
[exit status: 128]
$ git worktree remove ../hotfix
$ git worktree list
$LAB/ex2/answers-m14/ex-14-1 acd049c [feature/unicode]
$ git branch
* feature/unicode
  hotfix/blocklist
  main
```
<!-- /snippet -->

1. A file, not a directory. It holds one line, `gitdir: <path>`, which points at `.git/worktrees/hotfix` inside the main repository.
2. Shared: the object database, all refs, the configuration. Per worktree: `HEAD`, the index, the working tree, and the state of operations in progress (a rebase, a merge, a bisect).
3. `fatal: 'hotfix/blocklist' is already used by worktree at ...`. A branch can be checked out in one worktree only; otherwise a commit in one would move the branch under the other's index and working tree.
4. On the branch `hotfix/blocklist`, which the last command still lists: removing a worktree removes a directory and its admin entry, not the branch. With `--detach` there would have been no branch, and the commit would have been held by that worktree's HEAD reflog only, which is deleted with the worktree (exercise 14.9).

**Reasoning.** A linked worktree is a second checkout of the same repository. The edit on `feature/unicode` and the untracked file were never touched, because nothing was done to that working tree.

**Common mistakes.** Deleting the directory with `rm -rf` instead of `git worktree remove` (repair with `git worktree prune`). Creating the worktree inside the main working tree, where it shows up as untracked. Expecting `git stash` to be per worktree: the stash is shared.

**Expert approach.** Name the branch when you create the worktree (`-b`), keep worktrees next to the repository, and look at `git worktree list` before deleting branches.

**Reference.** Chapter 25, section 25.2 (what a linked worktree is), section 25.3 (what is shared), section 25.4 (one branch, one worktree) and section 25.6 (remove).

### Exercise 14.2

**Solution.**

<!-- snippet: ex2/answers-m14/14-2-attributes -->
```text
$ cat .gitattributes
*.ipynb          -diff
*.jsonl          text eol=lf
docs-internal.md export-ignore
$ git check-attr -a -- notebooks/eval.ipynb data/golden.jsonl docs-internal.md guard/rules.py
notebooks/eval.ipynb: diff: unset
data/golden.jsonl: text: set
data/golden.jsonl: eol: lf
docs-internal.md: export-ignore: set
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m14/14-2-effects -->
```text
$ sed -e 's/41/43/' notebooks/eval.ipynb > n.tmp && mv n.tmp notebooks/eval.ipynb
$ git diff
diff --git a/notebooks/eval.ipynb b/notebooks/eval.ipynb
index e6880ca..c62553a 100644
Binary files a/notebooks/eval.ipynb and b/notebooks/eval.ipynb differ
$ git add -A && git commit -q -m 'Add attributes for notebooks, data and internal notes'
$ git archive HEAD | tar -t
.gitattributes
README.md
data/
data/golden.jsonl
guard/
guard/rules.py
notebooks/
notebooks/eval.ipynb
```
<!-- /snippet -->

1. "Binary files ... differ": with `-diff` Git does not produce a textual diff for the path. The commit records the new blob exactly as before; the attribute changes the display, not the storage.
2. `docs-internal.md`. It is tracked and committed (it is still in `git ls-files`); `export-ignore` only keeps it out of `git archive`.
3. `diff=<driver>` and `merge=<driver>` with your own drivers, and `filter=<name>`: the attribute names a driver or filter, and the program behind the name is defined in configuration, which a clone does not receive.
4. No attribute is set for that path, so every default applies.

**Reasoning.** `.gitattributes` is a tracked file, so its lines reach every clone. What they can do without further setup is limited to behavior that is built into Git.

**Common mistakes.** Expecting `export-ignore` to act like `.gitignore`. Believing that `-diff` shrinks the repository. Committing `.gitattributes` after the files it should affect and expecting old commits to change.

**Expert approach.** `git check-attr -a -- <path>` before debugging any odd diff, merge or line-ending behavior: it answers "which rules apply to this path" in one line.

**Reference.** Chapter 14C, section 14C.4 (`.gitattributes`: syntax, `export-ignore`, `git check-attr`, which attributes need configuration), section 14C.5 (`text`, `eol`) and section 14C.6 (`-diff`).

### Exercise 14.3

**Solution.**

<!-- snippet: ex2/answers-m14/14-3-hook -->
```text
$ cat .git/hooks/pre-commit
#!/bin/sh
# Refuse a commit whose staged changes add the marker "DO NOT COMMIT".
if git diff --cached | grep -q '^+.*DO NOT COMMIT'; then
  echo "pre-commit: staged changes contain DO NOT COMMIT" >&2
  exit 1
fi
$ chmod +x .git/hooks/pre-commit
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m14/14-3-fires -->
```text
$ echo 'MAX_CHARS = 1  # DO NOT COMMIT: local test' >> guard/rules.py
$ git commit -am 'Lower the limit'
pre-commit: staged changes contain DO NOT COMMIT
[exit status: 1]
$ git log --oneline -1
96fc01a Add README
$ git commit -q --no-verify -am 'Lower the limit' && git log --oneline -1
2edf8b2 Lower the limit
```
<!-- /snippet -->

1. The commit is made from the index. `git diff --cached` shows what will be committed; the working tree may contain more, or less.
2. The hook's exit status. `pre-commit` runs before the message is even asked for; a status other than 0 stops the commit.
3. `--no-verify` skips the `pre-commit` and `commit-msg` hooks. A clone does not contain `.git/hooks`: hooks are not part of the repository's content, so a colleague gets nothing.
4. Where the author of a commit cannot switch it off: on the server (rules for the protected branch, required status checks) and in CI. A client-side hook is a convenience that catches mistakes early.

**Reasoning.** A hook is a program on your machine that Git runs at a fixed point. It can read the proposed commit and veto it, and the person at the keyboard can decline the veto.

**Common mistakes.** Forgetting `chmod +x`: Git then ignores the hook (exercise 14.7). Checking the working tree. Printing the reason to standard output only, or not at all: say why on standard error. Writing a slow hook, which teaches everyone to use `--no-verify`.

**Expert approach.** Keep hooks fast and specific, version them in the repository, activate them with `core.hooksPath`, and run the same check in CI, where it counts.

**Reference.** Chapter 14C, section 14C.9 (hooks: arguments, exit status), section 14C.10 (worked hooks), section 14C.11 (`--no-verify`, `core.hooksPath`, sharing hooks) and section 14C.13 (why hooks cannot enforce policy).

### Exercise 14.4

**Solution.**

<!-- snippet: ex2/answers-m14/14-4-stash -->
```text
$ git status -sb
## main
 M README.md
M  guard/limits.py
?? todo.txt
$ git stash push -u -m "limits, readme, todo"
Saved working directory and index state On main: limits, readme, todo
$ git status -sb
## main
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m14/14-4-graph -->
```text
$ git log --graph --oneline stash@{0}
*-.   d11cf43 On main: limits, readme, todo
|\ \  
| | * 4ec8018 untracked files on main: 0b775d2 Add turn limit
| * 80149af index on main: 0b775d2 Add turn limit
|/  
* 0b775d2 Add turn limit
* ddba234 Add README
* 314846b Add prompt rules
```
<!-- /snippet -->

Three new commits. The stash commit `d11cf43` is a merge with three parents: the commit you were on, a commit that records the index, and a commit that records the untracked files.

<!-- snippet: ex2/answers-m14/14-4-parents -->
```text
$ git show -s --format='%h parents: %p' stash@{0}
d11cf43 parents: 0b775d2 80149af 4ec8018
$ git diff --stat stash@{0}^1 stash@{0}^2
 guard/limits.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git diff --stat stash@{0}^1 stash@{0}
 README.md       | 2 ++
 guard/limits.py | 2 +-
 2 files changed, 3 insertions(+), 1 deletion(-)
$ git ls-tree -r --name-only stash@{0}^3
todo.txt
```
<!-- /snippet -->

The second parent differs from `HEAD` by the staged change only. The stash commit itself holds the working tree: the staged and the unstaged change. The third parent's tree contains `todo.txt` and nothing else, and it has no parent of its own, which is why its line in the graph ends there.

Without `-u` there is no third parent: the stash commit has two parents, and the untracked file stays in the working tree.

**Reasoning.** A stash entry is built from ordinary commits so that every existing mechanism (objects, refs, reflog, merge) can handle it. `refs/stash` points at the newest stash commit, and the list of stashes is that ref's reflog.

**Common mistakes.** Drawing the three commits as a chain. Expecting the untracked files in the stash commit's own tree. Forgetting that the index is saved separately, which is what `git stash pop --index` restores.

**Expert approach.** Address the parts directly when a pop conflicts or a stash was dropped: `git diff stash@{0}^1 stash@{0}` is the working tree change, `stash@{0}^2` the index, `git show stash@{0}^3:<path>` an untracked file.

**Reference.** Chapter 14C, section 14C.2 (a stash entry is a small commit graph). Stash basics: Chapter 11, section 11.11.

### Exercise 14.5

**Solution.**

<!-- snippet: ex2/answers-m14/14-5-conflict -->
```text
$ git merge -q feat/length-limit
$ git merge feat/audit-log
Auto-merging CHANGELOG.md
CONFLICT (content): Merge conflict in CHANGELOG.md
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git merge --abort
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m14/14-5-union -->
```text
$ echo 'CHANGELOG.md merge=union' > .gitattributes
$ git add .gitattributes && git commit -q -m 'Merge the changelog with the union driver'
$ git merge feat/audit-log
Auto-merging CHANGELOG.md
Merge made by the 'ort' strategy.
 CHANGELOG.md   | 1 +
 guard/audit.py | 2 ++
 2 files changed, 3 insertions(+)
 create mode 100644 guard/audit.py
$ cat CHANGELOG.md
# Changelog

- Add prompt rules
- Raise the length limit to 12000 characters
- Log every verdict
```
<!-- /snippet -->

One line in `.gitattributes`, `CHANGELOG.md merge=union`, committed on `main`. The built-in `union` driver resolves a conflicting hunk by keeping the lines of both sides, so the second merge completes by itself with both entries.

The driver is wrong, without any message, whenever "both" is not the right answer: two branches that edit the same existing line (you get both versions), a deletion on one side against an edit on the other, and any file where order or uniqueness matters, such as a lock file or a list with a count. It also places the lines in an order that it chooses.

**Reasoning.** A changelog conflicts because every branch appends at the same place, and the right resolution is always "keep both". That is the one case `union` is made for. The attribute works in every clone because the driver is built in.

**Common mistakes.** Setting the attribute in `.git/info/attributes`, where it applies to your clone only. Applying `merge=union` to source code or to dependency files. Committing the attribute on a feature branch, so that it is not in effect on the branch where the merge happens.

**Expert approach.** Remove the cause where you can: one file per change in a `changelog.d/` directory never conflicts. Where the single file stays, `merge=union` plus a look at the result in review.

**Reference.** Chapter 14C, section 14C.7 (merge drivers: `union`, `-merge`, your own) and section 14C.4.

### Exercise 14.6

**Solution.**

<!-- snippet: ex2/answers-m14/14-6-commit -->
```text
$ echo '# one' >> guard/rules.py && git commit -q -am 'One'
[hook] pre-commit
[hook] prepare-commit-msg
[hook] commit-msg
[hook] post-commit
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m14/14-6-no-verify -->
```text
$ echo '# two' >> guard/rules.py && git commit -q --no-verify -am 'Two'
[hook] prepare-commit-msg
[hook] post-commit
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m14/14-6-amend -->
```text
$ git commit -q --amend --no-edit
[hook] pre-commit
[hook] prepare-commit-msg
[hook] commit-msg
[hook] post-commit
[hook] post-rewrite
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m14/14-6-merge -->
```text
$ git merge -q --no-ff --no-edit topic
[hook] pre-merge-commit
[hook] prepare-commit-msg
[hook] commit-msg
[hook] post-merge
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m14/14-6-rebase -->
```text
$ git switch -q -c side HEAD~1
[hook] post-checkout
$ echo three > three.txt && git add three.txt && git commit -q --no-verify -m 'Three'
[hook] prepare-commit-msg
[hook] post-commit
$ git rebase -q main
[hook] pre-rebase
[hook] post-checkout
[hook] prepare-commit-msg
[hook] post-commit
[hook] post-rewrite
```
<!-- /snippet -->

- A commit runs four hooks in this order. `--no-verify` skips two of the three that can veto (`pre-commit`, `commit-msg`); `prepare-commit-msg`, which can also stop the commit by exiting non-zero, and `post-commit`, which cannot, still run.
- An amend runs the four and then `post-rewrite`, because it replaced a commit.
- A merge that creates a merge commit runs `pre-merge-commit` in place of `pre-commit`, then the two message hooks, then `post-merge`. It does not run `post-commit`.
- `git switch` runs `post-checkout`.
- A rebase runs `pre-rebase` once, `post-checkout` when it moves to the new base, `prepare-commit-msg` and `post-commit` for the commit it replays, and `post-rewrite` at the end. It runs neither `pre-commit` nor `commit-msg`.

Of the nine, the hooks that can stop their command are `pre-commit`, `prepare-commit-msg`, `commit-msg`, `pre-merge-commit` and `pre-rebase`. The others run after the fact, and their exit status changes nothing. For a team this means two gaps in a hook-based quality gate that exist without anyone bypassing anything on purpose: commits created by a rebase are not checked by `pre-commit` or `commit-msg`, and merges take a different hook. Together with `--no-verify`, that is why the gate belongs on the server.

**Reasoning.** Each command has its own fixed list of hook points. "The commit hooks" run for `git commit`; other commands that create commits use other points.

**Common mistakes.** Expecting `--no-verify` to skip all hooks. Expecting `pre-commit` during a rebase or a merge. Putting a check into `post-commit` and wondering why a failing check does not stop anything.

**Expert approach.** When a hook must see every commit that will be published, use `pre-push`, which receives the range, and repeat the check in CI. Use `git hook run <name>` to test a hook without creating commits.

**Reference.** Chapter 14C, section 14C.9 (the hook table: which command runs which hook, and which can veto), section 14C.10 and section 14C.11 (`--no-verify`). The full list is `git help hooks`.

### Exercise 14.7

**Solution.** The commit is on the server:

<!-- snippet: ex2/answers-m14/14-7-symptom -->
```text
$ git -C you log --oneline -3 origin/main
6018f24 PG-7: Add commit-msg hook for ticket numbers
94ea517 Add README
f25894f Add prompt rules
$ git -C you fetch -q && git -C you log --oneline -2 origin/main
c54589b fix readme
6018f24 PG-7: Add commit-msg hook for ticket numbers
```
<!-- /snippet -->

First hypothesis: Asha's clone does not know where the hooks are, because `core.hooksPath` is configuration and is not cloned.

<!-- snippet: ex2/answers-m14/14-7-config -->
```text
$ git -C you config get core.hooksPath
.githooks
$ git -C asha config get core.hooksPath
.githooks
```
<!-- /snippet -->

Rejected: both clones have the setting, so she did run the setup step. Reproduce in her clone:

<!-- snippet: ex2/answers-m14/14-7-reproduce -->
```text
$ cd asha
$ git commit --allow-empty -m 'no ticket'
hint: The '.githooks/commit-msg' hook was ignored because it's not set as executable.
hint: You can disable this warning with `git config set advice.ignoredHook false`.
[main 697b6ea] no ticket
$ git reset -q --hard HEAD~1
```
<!-- /snippet -->

Git says it: the hook was ignored because it is not executable. (The empty commit is removed again.) Why is it executable in your clone and not in hers?

<!-- snippet: ex2/answers-m14/14-7-mode -->
```text
$ git ls-files --stage .githooks/commit-msg
100644 4928fcbdfa32fc67fe8640a6fa0d64f002969353 0	.githooks/commit-msg
$ git -C ../you status -sb
## main...origin/main [behind 1]
 M .githooks/commit-msg
$ git -C ../you diff
diff --git a/.githooks/commit-msg b/.githooks/commit-msg
old mode 100644
new mode 100755
```
<!-- /snippet -->

The file is committed with mode `100644`. In your clone, `git status` has been showing one modified file for some time: the diff is "old mode 100644, new mode 100755". You made the hook executable locally and never committed that. Every other clone checks the file out as committed, without the executable bit, and Git skips it with a hint that is easy to miss.

Root cause: an uncommitted mode change. The fix is to commit it:

<!-- snippet: ex2/answers-m14/14-7-fix -->
```text
$ cd ../you
$ git pull -q && git add .githooks/commit-msg && git commit -q -m 'PG-8: Make the commit-msg hook executable' && git push -q
$ git ls-files --stage .githooks/commit-msg
100755 4928fcbdfa32fc67fe8640a6fa0d64f002969353 0	.githooks/commit-msg
$ cd ../asha && git pull -q
$ git commit --allow-empty -m 'still no ticket'
commit-msg: the subject must start with a ticket such as PG-123: 
[exit status: 1]
```
<!-- /snippet -->

After a pull, Asha's clone rejects a subject without a ticket.

The commit `fix readme` stays. It is on `main`, others may have it, and its content is fine: rewriting published history to repair a subject line costs more than the defect. And the lesson is the general one: this policy held only as long as every clone was set up correctly. To keep such a commit off `main`, the check must run where the author cannot skip it and a broken setup cannot disable it: a server-side rule for commit messages or a required CI check on pull requests.

**Reasoning.** Three things have to be true for a shared hook to run: the file is in the repository, `core.hooksPath` points at it in this clone, and the file is executable in this clone. The first and the third travel with commits (Git records the executable bit as part of the mode); the second never does.

**Common mistakes.** Stopping at "hooks are not cloned" without checking the configuration. Telling Asha to `chmod +x` on her machine, which repairs one clone and gives her a modified file. Overlooking a lone ` M` in your own `git status`. Rewriting `main` to fix the subject.

**Expert approach.** `git ls-files --stage <hook>` shows the committed mode; `git update-index --chmod=+x <hook>` sets it without touching the file. Add the hook check to CI as well, and make the setup step verifiable: a script that prints `git config get core.hooksPath` and tests `-x` on each hook.

**Reference.** Chapter 14C, section 14C.9 (a hook is an executable file; files without the bit are ignored), section 14C.11 (`core.hooksPath`, why hooks are not cloned, sharing hooks) and section 14C.13 (what does enforce policy). File modes in the index: Chapter 4 and Chapter 5, section 5.11.

### Exercise 14.8

**Solution.**

<!-- snippet: ex2/answers-m14/14-8-symptom -->
```text
$ git merge feat/timeouts
Auto-merging guard/client.yaml
CONFLICT (content): Merge conflict in guard/client.yaml
Resolved 'guard/client.yaml' using previous resolution.
Automatic merge failed; fix conflicts and then commit the result.
[exit status: 1]
$ git status -sb
## main
UU guard/client.yaml
$ cat guard/client.yaml
model: guard-small
timeout_seconds: 5
retries: 3
```
<!-- /snippet -->

One line in the middle explains everything: `Resolved 'guard/client.yaml' using previous resolution.` Rerere is enabled in this repository. At some earlier time the same conflict was resolved (in a hurry, keeping `main`'s values) and that merge was thrown away. Rerere had recorded the resolution, and it replayed it now.

<!-- snippet: ex2/answers-m14/14-8-diagnose -->
```text
$ git ls-files -u
100644 5bb97dd5ba1f0f632835a7d77e55ea4f483b3eaa 1	guard/client.yaml
100644 bafabc3768ded1325730d6534b48831b9788bf4e 2	guard/client.yaml
100644 02244956f4e396aba541cea6295ea9f5c0639bb2 3	guard/client.yaml
$ git diff
diff --cc guard/client.yaml
index bafabc3,0224495..0000000
--- a/guard/client.yaml
+++ b/guard/client.yaml
$ git rerere status
$ cat .git/rr-cache/*/postimage
model: guard-small
timeout_seconds: 5
retries: 3
```
<!-- /snippet -->

The index still has stages 1, 2 and 3 for the path, which is why `git status` says `UU` and the merge reports a conflict: rerere writes the remembered result into the working tree and leaves the decision to stage it to you (unless `rerere.autoUpdate` is set). `git rerere status` is empty after a replay; the recorded result is the `postimage` file under `.git/rr-cache`.

Forget the record, rebuild the conflict, resolve it properly:

<!-- snippet: ex2/answers-m14/14-8-fix -->
```text
$ git rerere forget guard/client.yaml
Updated preimage for 'guard/client.yaml'
Forgot resolution for 'guard/client.yaml'
$ git restore --merge guard/client.yaml
$ cat guard/client.yaml
model: guard-small
<<<<<<< ours
timeout_seconds: 5
retries: 3
=======
timeout_seconds: 30
retries: 1
>>>>>>> theirs
# edit guard/client.yaml: timeout 30 from the branch, retries 3 from main
$ git add guard/client.yaml && git commit -q --no-edit
Recorded resolution for 'guard/client.yaml'.
$ cat guard/client.yaml
model: guard-small
timeout_seconds: 30
retries: 3
$ git log --oneline --graph -4
*   d81e6bf Merge branch 'feat/timeouts'
|\  
| * 43d5471 Raise the classifier timeout to 30 seconds
* | 7fa0578 Fail fast and retry three times
|/  
* 69c3c04 Add classifier client settings
```
<!-- /snippet -->

`git rerere forget` deletes the recorded resolution for the conflict in that path. `git restore --merge` rebuilds the conflicted file from the three stages. The commit prints `Recorded resolution`: rerere has replaced the wrong record by the right one, so the wrong one cannot return.

**Reasoning.** Rerere stores pairs of "conflict, resolution" and replays a resolution whenever the same conflict text appears. It cannot judge whether the stored resolution was right. The stop with `UU` is the review point, and the single line in the merge output is the only signal that the file was filled in for you.

**Common mistakes.** `git add` and commit because "there are no markers". Editing the file to the right values without `git rerere forget`: that works too (the commit records the new resolution), but only if you notice in the first place. Deleting `.git/rr-cache` wholesale, which throws away every good resolution. Using `git checkout --ours` or `--theirs`: neither side is the right answer here.

**Expert approach.** Read the output of every merge and rebase in a repository with rerere for the word "Resolved", and `git diff` before `git add`: for a path in conflict state it shows the combined diff against both sides. Leave `rerere.autoUpdate` off unless tests run before every commit of a merge.

**Reference.** Chapter 14C, section 14C.3 (rerere: what is recorded, the replay, the wrong resolution, `git rerere forget`, `git restore --merge`, `rerere.autoUpdate`). Index stages: Chapter 8, section 8.8.

### Exercise 14.9

**Solution.**

<!-- snippet: ex2/solve-m14-redactor/01-observe -->
```text
$ git status -sb
## feature/names
$ git worktree list
$LAB/ex2/solve-m14-redactor/redactor a2c2602 [feature/names]
$ git log --oneline --all --graph
* a2c2602 Start name detection
* 4112250 Add redaction audit record
* 18c5b38 Add README
* bfda032 Add email and phone redaction
$ git reflog -4
a2c2602 HEAD@{0}: commit: Start name detection
4112250 HEAD@{1}: checkout: moving from main to feature/names
4112250 HEAD@{2}: commit: Add redaction audit record
18c5b38 HEAD@{3}: commit: Add README
$ ls .git/worktrees 2>/dev/null | wc -l
       0
```
<!-- /snippet -->

One worktree, no branch with the commits, a HEAD reflog that shows only the feature branch, and no entry left under `.git/worktrees`. Every linked worktree has its own `HEAD` and its own HEAD reflog, stored in `.git/worktrees/<name>/`. The two commits were made on that detached `HEAD`, so that reflog was the only thing that named them, and `git worktree remove` deleted it together with the entry. The reflog you looked at belongs to the main worktree, whose `HEAD` never went near those commits.

The objects are in the shared object database, unreachable. That is a job for `git fsck`:

<!-- snippet: ex2/solve-m14-redactor/02-fsck -->
```text
$ git fsck --lost-found
dangling commit c2ea81ff4be59e69fe6068f9a144bd89545274f5
$ git log --oneline --graph c2ea81f
* c2ea81f Redact IBANs
* a8c7476 Redact ten-digit phone numbers
* 18c5b38 Add README
* bfda032 Add email and phone redaction
$ git show --stat --format='%h %an %ad%n%s' c2ea81f
c2ea81f Lab User Mon Sep 7 10:11:00 2026 +0530
Redact IBANs

 redactor/patterns.py | 1 +
 redactor/scrub.py    | 4 ++--
 2 files changed, 3 insertions(+), 2 deletions(-)
```
<!-- /snippet -->

One dangling commit, "Redact IBANs", with "Redact ten-digit phone numbers" beneath it and the release under that. Give it the name it should have had:

<!-- snippet: ex2/solve-m14-redactor/03-anchor -->
```text
$ git branch hotfix/pii-patterns c2ea81f
$ git log --oneline --decorate v2.1.0..hotfix/pii-patterns
c2ea81f (hotfix/pii-patterns) Redact IBANs
a8c7476 Redact ten-digit phone numbers
$ git describe hotfix/pii-patterns
v2.1.0-2-gc2ea81f
$ git fsck
```
<!-- /snippet -->

`git branch` with the commit ID creates the branch without touching `feature/names` or its working tree. The branch has the original commits (`git describe` counts two since `v2.1.0`), and `git fsck` no longer reports anything.

<!-- snippet: ex2/solve-m14-redactor/04-the-third-pattern -->
```text
$ git fsck --unreachable --no-reflogs
$ git show hotfix/pii-patterns:redactor/patterns.py
"""Patterns for personal data that must not reach the model or the logs."""

import re

EMAIL = re.compile(r"[\w.+-]+@[\w-]+\.[\w.]+")
PHONE = re.compile(r"\+?\d[\d -]{7,}\d")
IBAN = re.compile(r"[A-Z]{2}\d{2}[A-Z0-9]{11,30}")
$ git status -sb
## feature/names
$ cd ..
$ exercises/gen/m14-redactor/check.sh
Checking exercise m14-redactor
  ok    the branch hotfix/pii-patterns has two commits on top of v2.1.0
  ok    the first is "Redact ten-digit phone numbers"
  ok    the second is "Redact IBANs"
  ok    the branch starts exactly at the release tag
  ok    they are the original commits, not copies
  ok    HEAD is still on feature/names
  ok    feature/names still ends with "Start name detection"
  ok    the hotfix was not merged into feature/names
  ok    the working tree is clean
PASS: exercise m14-redactor is complete.
[exit status: 0]
```
<!-- /snippet -->

**The third pattern is gone.** It was an edit in the working tree of the removed worktree, never staged and never committed. `git add` writes a blob; an edit that was never added exists only as a file, and `git worktree remove --force` deleted the file. `git fsck --unreachable` lists nothing, and the patterns file on the recovered branch ends with the IBAN line. The card-number pattern must be typed again.

**Reasoning.** What Git stores, it keeps until garbage collection: the two commits were objects. What protects unreachable commits is a reflog, and this reflog lived in a directory that the removal deleted. That leaves a search of the object database, and a time limit: unreachable loose objects are pruned by a garbage collection once they are older than two weeks.

**Common mistakes.** Searching the main worktree's reflog again and again. `git worktree add` at the same path, hoping the reflog returns. Running `git gc` or `git worktree prune` "to tidy up" before searching. Checking out the dangling commit in the main working tree (detaching `HEAD` again) instead of creating a branch. Promising the third pattern back.

**Expert approach.** Before removing a worktree: `git -C <path> status --short` and `git -C <path> log --oneline -3`; if `HEAD` is detached and has commits, `git -C <path> switch -c <name>` first. `--force` on `git worktree remove` is 🔴 because it deletes uncommitted and untracked files with no way back. After the fact: `git fsck --lost-found`, then `git branch <name> <id>`.

**Reference.** Chapter 25, section 25.3 (each worktree has its own `HEAD` and reflog), section 25.6 (`remove`, `--force`), section 25.7 (commits on a detached worktree are held by nothing after removal) and section 25.8. Chapter 13, section 13.6 (`git fsck --lost-found`), section 13.8 (lost work in detached HEAD) and section 13.12 (what cannot be recovered: never-staged edits).

---

## Module 15: Submodules, subtrees, Git LFS

### Exercise 15.1

**Solution.**

<!-- snippet: ex2/answers-m15/15-1-add -->
```text
$ git submodule add ../metrickit.git vendor/metrickit
Cloning into '$LAB/ex2/answers-m15/ex-15-1/evalboard/vendor/metrickit'...
fatal: transport 'file' not allowed
fatal: clone of '../remotes/metrickit.git' into submodule path '$LAB/ex2/answers-m15/ex-15-1/evalboard/vendor/metrickit' failed
[exit status: 128]
$ git -c protocol.file.allow=always submodule add ../metrickit.git vendor/metrickit
Cloning into '$LAB/ex2/answers-m15/ex-15-1/evalboard/vendor/metrickit'...
done.
$ git status -s
A  .gitmodules
A  vendor/metrickit
$ cat .gitmodules
[submodule "vendor/metrickit"]
	path = vendor/metrickit
	url = ../metrickit.git
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m15/15-1-inspect -->
```text
$ git commit -q -m 'Add metrickit as a submodule'
$ git ls-tree HEAD vendor/
160000 commit d9161f6e73acfe30fa411f51266d06dbdd72b0e0	vendor/metrickit
$ git submodule status
 d9161f6e73acfe30fa411f51266d06dbdd72b0e0 vendor/metrickit (v0.2.0)
$ cat vendor/metrickit/.git
gitdir: ../../.git/modules/vendor/metrickit
$ git -C vendor/metrickit log --oneline -1
d9161f6 Add ROUGE-L
```
<!-- /snippet -->

1. The remote is a local path, which uses the `file` transport, and since Git 2.38.1 the submodule machinery refuses that transport unless `protocol.file.allow` permits it. `-c protocol.file.allow=always` permits it for this one command.
2. The file `.gitmodules` (path and URL) and one tree entry for `vendor/metrickit` with mode `160000` and type `commit`: a gitlink, the ID of a commit in the library's repository. No file of the library is stored in the superproject.
3. Under `.git/modules/vendor/metrickit` of the superproject. The directory `vendor/metrickit` contains a `.git` file that points there.
4. To the URL of the superproject's own remote, so that the pair of repositories can move to another server together.
5. An empty directory, and the entry in `.gitmodules`. The submodule has to be initialized and updated before files appear (exercises 15.4 and 15.7).

**Reasoning.** A submodule is three things: a gitlink in the tree (which commit), `.gitmodules` (where to get it), and a clone of the library kept inside the superproject's `.git` (the objects). Only the first two are in the commit.

**Common mistakes.** Setting `protocol.file.allow=always` in the global configuration to stop the error: it switches the protection off for every repository. Expecting the library's files in the superproject's history. Committing without `.gitmodules`.

**Expert approach.** After adding, `git submodule status` (a leading space means "checked out at the recorded commit") and `git diff --cached --submodule` before the commit.

**Reference.** Chapter 23, section 23.2 (gitlink, `.gitmodules`, `.git/modules`), section 23.3 (what a teammate receives) and section 23.4 (`protocol.file.allow`).

### Exercise 15.2

**Solution.**

<!-- snippet: ex2/answers-m15/15-2-track -->
```text
$ wc -c weights/encoder.bin
  300000 weights/encoder.bin
$ git lfs install --local
Updated Git hooks.
Git LFS initialized.
$ git lfs track "*.bin"
Tracking "*.bin"
$ cat .gitattributes
*.bin filter=lfs diff=lfs merge=lfs -text
$ git add .gitattributes weights && git commit -q -m 'Add encoder weights with Git LFS'
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m15/15-2-pointer -->
```text
$ git cat-file -p HEAD:weights/encoder.bin
version https://git-lfs.github.com/spec/v1
oid sha256:10ad8c763a4dbdc179599df1aa36608f74b40263cb4c3ced4d066d47189b7d2f
size 300000
$ git cat-file -s HEAD:weights/encoder.bin
131
$ wc -c weights/encoder.bin
  300000 weights/encoder.bin
$ git lfs ls-files
10ad8c763a * weights/encoder.bin
$ find .git/lfs/objects -type f
.git/lfs/objects/10/ad/10ad8c763a4dbdc179599df1aa36608f74b40263cb4c3ced4d066d47189b7d2f
```
<!-- /snippet -->

1. A pointer file of three lines and 131 bytes: the specification version, the SHA-256 of the content, the size.
2. In `.git/lfs/objects/`, in a file named by that SHA-256. The working tree has the full file too.
3. The clean filter (`git-lfs clean`) ran at `git add` and replaced the content by the pointer on the way into the index. The smudge filter (`git-lfs smudge`) runs at checkout and replaces the pointer by the content on the way out.
4. It wrote the `filter.lfs.*` settings into this repository's `.git/config` and installed LFS hooks in `.git/hooks`. Without `--local` the settings go into the global configuration, and the lab's rule is that nothing outside the sandbox repository is changed.
5. The content of the file is present locally. A minus sign means that only the pointer is there.

**Reasoning.** LFS is built from two general Git mechanisms: a filter named in `.gitattributes` and configured locally, and hooks. Git itself stores and transfers the pointer; the LFS client stores and transfers the content.

**Common mistakes.** Running `git lfs track` and forgetting to commit `.gitattributes`. Adding the large file before the pattern is tracked (exercise 15.6). Reading the 131 bytes as a sign that something went wrong.

**Expert approach.** After the first commit with LFS: `git lfs ls-files`, and `git cat-file -s HEAD:<path>` as proof that Git holds a pointer.

**Reference.** Chapter 22, section 22.3 (the pointer file and the two filters), section 22.4 (the `.gitattributes` line) and section 22.8 (the local store, `git lfs ls-files`).

### Exercise 15.3

**Solution.**

<!-- snippet: ex2/answers-m15/15-3-subtree -->
```text
$ git subtree add --prefix=vendor/metrickit ../remotes/metrickit.git main --squash
git fetch ../remotes/metrickit.git main
From ../remotes/metrickit
 * branch            main       -> FETCH_HEAD
Added dir 'vendor/metrickit'
$ git log --graph --oneline
*   2739bf5 Merge commit 'fb60a354ad5f82fdccc39eadf70fcf90dd2cadc9' as 'vendor/metrickit'
|\  
| * fb60a35 Squashed 'vendor/metrickit/' content from commit d86a1d5
* dcdbe44 Add README
* 27f8a73 Add evaluation dashboard
$ git ls-tree HEAD vendor/
040000 tree c00c144d40721f6627b4390fabee1eb1494762d6	vendor/metrickit
$ ls -A vendor/metrickit
metrickit.py
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m15/15-3-message -->
```text
$ git log -1 --format=%B HEAD^2
Squashed 'vendor/metrickit/' content from commit d86a1d5

git-subtree-dir: vendor/metrickit
git-subtree-split: d86a1d59e531627f0ca98500a2fb82e633ba0d2f
```
<!-- /snippet -->

1. A tree (`040000`): an ordinary directory with ordinary blobs. The library's files are part of this repository's own history. There is no gitlink and no `.gitmodules`.
2. The files. A plain clone is complete, with no second step.
3. The second parent `fb60a35` is a squashed commit that contains the library's files at the root; the merge `2739bf5` places them under `vendor/metrickit`. The trailers record the directory (`git-subtree-dir`) and the library commit that was imported (`git-subtree-split`), which is how a later `git subtree pull` knows where to continue.
4. Simpler: cloning, CI, and switching branches need nothing special. Harder: the link to the upstream is two trailers in a message; sending changes back needs `git subtree push` or `split`, and the superproject's history grows with every imported version.

**Reasoning.** A subtree copies content in and uses a merge to place it. Nothing in Git marks the directory as foreign afterwards; the bookkeeping is in commit messages.

**Common mistakes.** Editing vendored files in passing, mixed into unrelated commits, which makes a later split hard. Leaving out `--squash` without meaning to, which imports the library's whole history. Expecting `git submodule` commands to know about it.

**Expert approach.** Decide by who changes the dependency and how often: a package manager when the library is published, a subtree when a small dependency rarely changes and clones must be self-contained, a submodule when the exact upstream commit and its history must stay visible.

**Reference.** Chapter 23, section 23.13 (subtrees: `add`, `pull`, `push`, `split`) and section 23.14 (submodule, subtree, or a package manager).

### Exercise 15.4

**Solution.**

<!-- snippet: ex2/answers-m15/15-4-status -->
```text
$ git submodule status
-fd523962aa88ca9d9775b1843548042e992b91c5 vendor/metrickit
$ ls -A vendor/metrickit | wc -l
       0
$ git -c protocol.file.allow=always submodule update --init
Submodule 'vendor/metrickit' (../remotes/metrickit.git) registered for path 'vendor/metrickit'
Cloning into '$LAB/ex2/answers-m15/ex-15-4/fresh/vendor/metrickit'...
done.
Submodule path 'vendor/metrickit': checked out 'fd523962aa88ca9d9775b1843548042e992b91c5'
$ git submodule status
 fd523962aa88ca9d9775b1843548042e992b91c5 vendor/metrickit (v0.2.0)
$ git -C vendor/metrickit status -sb
## HEAD (no branch)
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m15/15-4-moved -->
```text
$ git -C vendor/metrickit checkout -q v0.1.0
$ git submodule status
+d3bb361cd07961624a48250877027eafe01dd729 vendor/metrickit (v0.1.0)
$ git status -s
 M vendor/metrickit
$ git diff --submodule=log
Submodule vendor/metrickit fd52396..d3bb361 (rewind):
  < Add ROUGE-L
```
<!-- /snippet -->

The three first characters:

| Character | State |
|---|---|
| `-` | not initialized: the gitlink is recorded, nothing is checked out, the directory is empty |
| space | checked out at exactly the recorded commit |
| `+` | checked out at another commit than the one the superproject records |

After `update`, the submodule is in detached HEAD (`## HEAD (no branch)`): the superproject records a commit, not a branch, and `update` checks out that commit. In the last state `git diff --submodule=log` says `(rewind)`: the checkout is one library commit behind the recorded one. `git commit -am "..."` would stage that difference and record the older commit in the superproject: a rollback of the dependency inside a commit about something else.

**Reasoning.** `git submodule status` compares two values per submodule: the gitlink in the superproject's index and the `HEAD` of the submodule's repository. The first character is the result of the comparison.

**Common mistakes.** Reading `+` as "ahead". Treating ` M vendor/metrickit` in `git status` as noise. Being alarmed by the detached HEAD and creating a branch in the submodule on every machine.

**Expert approach.** `git status` is clean when the two values agree. When they do not, decide which one is right: `git submodule update` moves the checkout to the recorded commit; `git add vendor/metrickit` moves the record to the checkout. Never let `commit -a` decide.

**Reference.** Chapter 23, section 23.3 (init, update), section 23.5 (the detached HEAD after `update`), section 23.6 (status and diff) and section 23.7 (the stale submodule and the silent rollback).

### Exercise 15.5

**Solution.**

<!-- snippet: ex2/answers-m15/15-5-commands -->
```text
$ git subtree add -q --prefix=vendor/metrickit ../remotes/metrickit.git v0.1.0 --squash
git fetch ../remotes/metrickit.git v0.1.0
From ../remotes/metrickit
 * tag               v0.1.0     -> FETCH_HEAD
$ echo '# sorted by name' >> board.py && git commit -q -am 'Sort runs by name'
$ git subtree pull -q --prefix=vendor/metrickit ../remotes/metrickit.git v0.2.0 --squash
From ../remotes/metrickit
 * tag               v0.2.0     -> FETCH_HEAD
Merge made by the 'ort' strategy.
 vendor/metrickit/metrickit.py | 9 +++++++++
 1 file changed, 9 insertions(+)
```
<!-- /snippet -->

<!-- snippet: ex2/answers-m15/15-5-graph -->
```text
$ git log --graph --oneline
*   8c9c3ff Merge commit '84846687c8f23501d7e4ecf168e87d84e5a8b062'
|\  
| * 8484668 Squashed 'vendor/metrickit/' changes from 369ad7b..b9655f7
* | 5021106 Sort runs by name
* | 06aa901 Merge commit '66566db404439186c391672ad9ca2c713559c3a9' as 'vendor/metrickit'
|\| 
| * 66566db Squashed 'vendor/metrickit/' content from commit 369ad7b
* 846f7f6 Add README
* dc35953 Add evaluation dashboard
```
<!-- /snippet -->

Seven commits. Two of them, `66566db` and `8484668`, contain library files only (at the root of their tree); the second has the first as its parent, and the first has no parent at all. Each was merged into `main` by a merge commit: `06aa901` and `8c9c3ff`. The other three are the project's own commits.

The second squashed commit knows where to continue from the trailers of the first: `git subtree pull` reads `git-subtree-split` from the newest squash commit for that directory, squashes the range from that library commit to the new one (the subject says `changes from 369ad7b..b9655f7`), and commits the result on top of the previous squash commit.

**Reasoning.** With `--squash`, the library has a side line of its own inside your repository: one commit per imported version, each on top of the last, with a root that is unrelated to your history. Every import is a merge of that line into yours.

**Common mistakes.** Drawing the second squash commit without a parent. Drawing the squash commits on the first-parent line. Forgetting the commit between the two operations, which is why the lines cross in the graph.

**Expert approach.** `git log --first-parent --oneline` hides the side line and shows one merge per import, which is the readable view of a repository with subtrees.

**Reference.** Chapter 23, section 23.13. Merges and first-parent history: Chapter 8, section 8.13.

### Exercise 15.6

**Solution.**

<!-- snippet: ex2/answers-m15/15-6-late -->
```text
$ git lfs install --local
Updated Git hooks.
Git LFS initialized.
$ git lfs track "*.bin"
Tracking "*.bin"
$ git add .gitattributes && git commit -q -m 'Track weights with Git LFS'
$ git lfs ls-files
$ git cat-file -s HEAD:weights/encoder.bin
300000
$ git status -s
 M weights/encoder.bin
```
<!-- /snippet -->

1. Nothing: no committed file is an LFS pointer.
2. `300000`: the commit still holds the full content.
3. ` M weights/encoder.bin`: the file shows as modified although you did not touch it.

`git lfs track` wrote a line into `.gitattributes`. Attributes apply when a file passes through the filter, at `git add`; they do not rewrite what is already committed. The status line appears because Git now compares "what the clean filter would produce for this file" (a pointer) with what the index holds (the content).

<!-- snippet: ex2/answers-m15/15-6-renormalize -->
```text
$ git add --renormalize .
$ git status -s
M  weights/encoder.bin
$ git commit -q -m 'Convert the encoder weights to an LFS pointer'
$ git lfs ls-files
10ad8c763a * weights/encoder.bin
$ git cat-file -s HEAD:weights/encoder.bin
131
$ git cat-file -s HEAD~2:weights/encoder.bin
300000
```
<!-- /snippet -->

4. `M  weights/encoder.bin`: `git add --renormalize` ran the file through the clean filter and staged the pointer.
5. The file is listed, with an asterisk.
6. `131`.
7. `300000`: the commit from before the conversion is unchanged.

A clone still downloads the 300,000-byte blob, because it is part of history and every clone receives all of history. Only a rewrite of the commits that contain the blob changes that: `git lfs migrate import`, which gives every rewritten commit a new ID and, for pushed history, means a coordinated force push.

**Reasoning.** Tracking a pattern is a statement about future `git add` operations. Three states have to be told apart: the attribute (in `.gitattributes`), the content of the newest commit, and the content of history.

**Common mistakes.** Believing that `git lfs track` converts existing files. Committing the confusing "modified" file with `git commit -a` and not noticing that this is the conversion. Announcing that the repository is now small. Running `git lfs migrate import` on pushed history without agreement.

**Expert approach.** Track before the first add. For an existing repository, `git lfs migrate info` shows what a migration would touch; decide between converting from now on (this exercise) and rewriting history (Lab 15.4) by whether the old blobs are a real problem.

**Reference.** Chapter 22, section 22.4 (what tracking does not do), section 22.9 (`git lfs migrate`) and section 22.10 (the error "tracked too late"). `git add --renormalize`: Chapter 14C, section 14C.4.

### Exercise 15.7

**Solution.**

<!-- snippet: ex2/answers-m15/15-7-symptom -->
```text
$ python3 -B -c 'import board' 2>&1 | tail -1
ModuleNotFoundError: No module named 'vendor.metrickit.metrickit'
$ ls -A vendor/metrickit | wc -l
       0
$ git submodule status
-4ec76d4406774692cd6bb1d74d6acb38637ab0db vendor/metrickit
$ git ls-tree HEAD vendor/
160000 commit 4ec76d4406774692cd6bb1d74d6acb38637ab0db	vendor/metrickit
```
<!-- /snippet -->

The directory exists and is empty; `git submodule status` begins with `-`; the tree records a gitlink. Root cause: the clone was made without submodules, and nobody ran the second step. The developers' machines did it long ago.

<!-- snippet: ex2/answers-m15/15-7-fix -->
```text
$ git submodule update --init
Submodule 'vendor/metrickit' (../remotes/metrickit.git) registered for path 'vendor/metrickit'
Cloning into '$LAB/ex2/answers-m15/ex-15-7/ci/vendor/metrickit'...
fatal: transport 'file' not allowed
fatal: clone of '../remotes/metrickit.git' into submodule path '$LAB/ex2/answers-m15/ex-15-7/ci/vendor/metrickit' failed
Failed to clone 'vendor/metrickit'. Retry scheduled
Cloning into '$LAB/ex2/answers-m15/ex-15-7/ci/vendor/metrickit'...
fatal: transport 'file' not allowed
fatal: clone of '../remotes/metrickit.git' into submodule path '$LAB/ex2/answers-m15/ex-15-7/ci/vendor/metrickit' failed
Failed to clone 'vendor/metrickit' a second time, aborting
[exit status: 1]
$ git -c protocol.file.allow=always submodule update --init
Cloning into '$LAB/ex2/answers-m15/ex-15-7/ci/vendor/metrickit'...
done.
Submodule path 'vendor/metrickit': checked out '4ec76d4406774692cd6bb1d74d6acb38637ab0db'
$ git submodule status
 4ec76d4406774692cd6bb1d74d6acb38637ab0db vendor/metrickit (v0.2.0)
$ python3 -B -c 'import board; print("import ok")'
import ok
```
<!-- /snippet -->

The first attempt fails with `transport 'file' not allowed`. That is not part of the problem you were sent to solve: it is the sandbox. The library's URL is a local path, and Git refuses the `file` transport for submodules by default, because a repository's `.gitmodules` is content written by someone else, and a URL in it that points into the local filesystem can be used to read or copy data the cloning user did not intend to expose. With the option, for this one command, the update succeeds and the import works.

To get a complete clone in one step: `git clone --recurse-submodules <url>`, or, for clones that already exist and for every later pull and switch, `git config set submodule.recurse true`.

**Reasoning.** A plain clone copies the superproject. Its tree says "at this path, commit X of another repository", and Git creates an empty directory as a placeholder. Fetching the other repository is a separate, explicit action.

**Common mistakes.** Running `git submodule update` without `--init` on a submodule that was never initialized: it does nothing. Copying the library's files into the directory by hand. Making `protocol.file.allow=always` permanent, in a pipeline of all places. On a real server: forgetting that the pipeline's credentials must be able to read the second repository as well.

**Expert approach.** Put the recursion where it cannot be forgotten: in the clone command of the pipeline, and `submodule.recurse` in the developer setup. Treat an empty directory at a path listed in `.gitmodules` as this diagnosis until proven otherwise.

**Reference.** Chapter 23, section 23.3 (clone, init, update, `--recurse-submodules`), section 23.4 (`protocol.file.allow` and the security reason), section 23.7 (`submodule.recurse`) and section 23.12 (CI consequences).

### Exercise 15.8

**Solution.**

<!-- snippet: ex2/answers-m15/15-8-symptom -->
```text
$ python3 -B -c 'import load; load.load()' 2>&1 | tail -1
_pickle.UnpicklingError: invalid load key, 'v'.
$ wc -c weights/encoder.bin
     131 weights/encoder.bin
$ cat weights/encoder.bin
version https://git-lfs.github.com/spec/v1
oid sha256:10ad8c763a4dbdc179599df1aa36608f74b40263cb4c3ced4d066d47189b7d2f
size 300000
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

The "model file" is 131 bytes of text that begins with `version https://git-lfs...`: the loader was handed an LFS pointer, and `v` is its first character.

<!-- snippet: ex2/answers-m15/15-8-diagnose -->
```text
$ git lfs ls-files
10ad8c763a - weights/encoder.bin
$ git config get filter.lfs.smudge
[exit status: 1]
$ cat .gitattributes
*.bin filter=lfs diff=lfs merge=lfs -text
```
<!-- /snippet -->

`git lfs ls-files` marks the file with a minus sign: pointer only. `.gitattributes` asks for the `lfs` filter, and this clone has no such filter configured (`filter.lfs.smudge` is unset). Git therefore checked the blob out as it is stored. Root cause: the repository was cloned on a machine, or in a configuration, where Git LFS is not set up.

<!-- snippet: ex2/answers-m15/15-8-fix -->
```text
$ git lfs install --local
Updated Git hooks.
Git LFS initialized.
$ git lfs pull
$ wc -c weights/encoder.bin
  300000 weights/encoder.bin
$ git lfs ls-files
10ad8c763a * weights/encoder.bin
$ git status -sb
## main...origin/main
```
<!-- /snippet -->

`git lfs install --local` configures the filter in this repository; `git lfs pull` downloads the object and replaces the pointer in the working tree.

`git status` was clean all along because, without a filter, the working tree file is byte for byte what the commit contains: the pointer. Nothing was modified. A pipeline should fail early and by name: check that the LFS client exists (`git lfs version`), and after checkout that no tracked LFS path is still a pointer, for example that `git lfs ls-files` shows no minus sign, or that the model file has the size the pointer states.

**Reasoning.** An attribute names a filter; the configuration defines it. A clone receives the first and never the second. When the definition is missing, Git does not fail: it treats the attribute as naming nothing and checks out the stored bytes.

**Common mistakes.** Suspecting a corrupted upload. Re-cloning on the same machine. Running `git lfs install` without `--local` in the lab. Committing from the clone before the filter is configured. Setting `GIT_LFS_SKIP_SMUDGE=1` in a base image and forgetting it, which produces the same symptom with LFS installed.

**Expert approach.** The first command for any odd binary file in a repository with LFS: `git lfs ls-files`, then `git check-attr filter -- <path>` and `git config get filter.lfs.smudge`. The three answers locate the fault: not tracked, not configured, or not downloaded.

**Reference.** Chapter 22, section 22.7 (what a clone receives without the client; `git lfs pull`; `GIT_LFS_SKIP_SMUDGE`), section 22.3 and section 22.10 (common errors). Filters are defined in configuration: Chapter 14C, section 14C.8.

### Exercise 15.9

**Solution.**

<!-- snippet: ex2/solve-m15-evalboard/01-observe -->
```text
$ git status -sb
## main...origin/main
 M vendor/metrickit
$ git submodule status
+d9161f6e73acfe30fa411f51266d06dbdd72b0e0 vendor/metrickit (v0.2.0)
$ git diff --submodule=log
Submodule vendor/metrickit ef17366..d9161f6:
  > Add ROUGE-L
```
<!-- /snippet -->

The line you have been ignoring: ` M vendor/metrickit`. The `+` says that the submodule is checked out at another commit than `main` records.

<!-- snippet: ex2/solve-m15-evalboard/02-two-machines -->
```text
$ git ls-tree HEAD vendor/
160000 commit ef173667db65cda30d26ff50ebf1cfb78dc5cb54	vendor/metrickit
$ git -C vendor/metrickit describe HEAD
v0.2.0
$ git -C vendor/metrickit describe $(git rev-parse HEAD:vendor/metrickit)
v0.1.0
$ python3 -B -c 'import board; print("import ok")'
import ok
```
<!-- /snippet -->

That answers request 1. `main` records the library at `v0.1.0`, which has no `rouge_l`. Your working tree has the library at `v0.2.0`, which has it. Your machine runs what is checked out; the build machine makes a fresh recursive clone and gets what is recorded. The import "works" for you because your submodule is stale in the lucky direction.

When did the record change?

<!-- snippet: ex2/solve-m15-evalboard/03-history-of-the-pointer -->
```text
$ git log --format='%h %an: %s' -- vendor/metrickit
dec30ed Ravi Menon: Sort runs by date
282e096 Asha Rao: Use metrickit 0.2.0
c4e2778 Lab User: Add metrickit 0.1.0 as a submodule
$ git show --stat --format='%h %an: %s' dec30ed
dec30ed Ravi Menon: Sort runs by date

 README.md        | 2 ++
 runs.py          | 2 ++
 vendor/metrickit | 2 +-
 3 files changed, 5 insertions(+), 1 deletion(-)
$ git show --submodule=log --format= dec30ed -- vendor/metrickit
Submodule vendor/metrickit d9161f6..ef17366 (rewind):
  < Add ROUGE-L
```
<!-- /snippet -->

Three commits touched the gitlink. The newest is `dec30ed`, "Sort runs by date", by Ravi: a commit about sorting whose `--stat` has a third line, `vendor/metrickit | 2 +-`, and `--submodule=log` calls the change a rewind that takes "Add ROUGE-L" away. Ravi's submodule was still at 0.1.0 when he pulled Asha's update; he committed with `git commit -a`, which staged the stale checkout as if it were a decision.

The commit is pushed, and two commits sit on top of it. The fix is a new commit that moves the pointer forward again. Your submodule is already at the right commit, so staging it is the whole change:

<!-- snippet: ex2/solve-m15-evalboard/04-fix -->
```text
$ git tag answer/rollback dec30ed
$ git add vendor/metrickit
$ git status -s
M  vendor/metrickit
$ git commit -q -m 'Use metrickit 0.2.0 again' -m 'Commit dec30ed moved the submodule pointer back to 0.1.0 by accident. The dashboard needs rouge_l, which 0.2.0 added.'
$ git ls-tree HEAD vendor/
160000 commit d9161f6e73acfe30fa411f51266d06dbdd72b0e0	vendor/metrickit
$ git push
To ../remotes/evalboard.git
   d28ca07..8d01151  main -> main
```
<!-- /snippet -->

<!-- snippet: ex2/solve-m15-evalboard/05-verify -->
```text
$ git submodule status
 d9161f6e73acfe30fa411f51266d06dbdd72b0e0 vendor/metrickit (v0.2.0)
$ git status -sb
## main...origin/main
$ git -c protocol.file.allow=always clone -q --recurse-submodules ../remotes/evalboard.git ../verify
$ (cd ../verify && python3 -B -c 'import board; print("import ok")')
import ok
$ rm -rf ../verify
```
<!-- /snippet -->

The status line is gone, the prefix is a space, and a fresh recursive clone (what the build machine does) imports the module.

<!-- snippet: ex2/solve-m15-evalboard/06-prevent -->
```text
$ git config set submodule.recurse true
$ cd ..
$ exercises/gen/m15-evalboard/check.sh
Checking exercise m15-evalboard
  ok    the tag answer/rollback names the commit that moved the pointer back
  ok    main records metrickit 0.2.0 again
  ok    nothing was rewritten (the 0.5.0 commit is an ancestor of main)
  ok    the fix is pushed
  ok    the submodule is checked out at the recorded commit
  ok    the working tree of the superproject is clean
  ok    submodule.recurse is true in your clone
PASS: exercise m15-evalboard is complete.
[exit status: 0]
```
<!-- /snippet -->

With `submodule.recurse`, `pull`, `switch` and `checkout` update the submodule's working tree together with the superproject, so a stale checkout does not arise in the first place.

**Reasoning.** A superproject and its submodule have two `HEAD`s, and no default ties them together. After a pull that moves the gitlink, the submodule's checkout is behind, `git status` reports it as modified, and any command that stages "everything modified" turns the stale state into a commit. Reviewers miss it because the diff is one line with two commit IDs.

**Common mistakes.** Running `git submodule update` first "to clean up the status": that checks out 0.1.0, your import breaks, and you have reproduced the build failure instead of fixing it (it is recoverable: check out `v0.2.0` in the submodule again). Reverting Ravi's commit, which also removes the sorting. Amending or rebasing pushed history. Fixing only your clone. Looking for the cause in `board.py`, which nobody changed.

**Expert approach.** `git log --oneline -- <submodule path>` is the history of the pointer; add `-p --submodule=log` to read each move as library commits. In review, treat any change to a gitlink as a dependency upgrade or downgrade that needs a sentence in the message. In CI, a check that a gitlink never moves to an ancestor of its previous value catches the rollback mechanically.

**Reference.** Chapter 23, section 23.7 (the stale submodule and the silent rollback; a pushed rollback is fixed with a new commit; `submodule.recurse`), section 23.6 (status and diff of a pointer) and section 23.12 (what CI sees).
