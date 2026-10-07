# V067: git log is a graph query: selection, filters, graph shape and output formats

- **Part.** 3, Investigation, recovery and power tools
- **Module.** 11, History investigation
- **Planned minutes.** 24
- **Prerequisites.** V020, V066
- **Textbook sections.** [Chapter 14A](../../textbook/ch14a-history-investigation.md), sections 14A.1, 14A.9 and 14A.15
- **Demo scripts.** `labs/ch14a/history-tour.sh`, `labs/ch14a/log-graph.sh`, `labs/ch14a/log-filters.sh`, `labs/ch14a/log-formats.sh`

## HOOK

**[ON SCREEN]** One line: "The nightly evaluation scored 0.800 last Wednesday and 0.400 today, on the same model checkpoint."

It's Tuesday morning, and your CTO asks: is it the model, the data, or our own harness? Which commit, who wrote it, why, and is it in the release that went out on Friday?

You open a terminal and type `git log`. Thirty-odd commits scroll past. A commit is one saved snapshot of the whole project, with a note about who saved it and why. You've read all of them and answered none of the four questions. Then you try to narrow it down by date, you type `--since=2026-09-10`, and the commits from the morning of the tenth aren't in the output. Nothing is wrong with the repository. The query was wrong, and Git didn't tell you.

This video is about asking `git log` a question it can answer, and knowing why the answer is what it is. Keep that missing morning in mind. It comes back.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. In the previous video you read diffs. A diff, the lines removed and added, is a query over a pair of snapshots. Today's query is over the graph. Every commit names the commit it was built on, its parent, and those links form the graph. Which commits are in this set, and what do I print about each one?

You'll work in `scorekit`, a small library that scores model answers against reference answers. Its history was prepared for Chapter 14A: nine days, three authors, three renames, one formatter commit, one deleted file, a merge that joined two lines of work, a squash merge, an unmerged branch, and two regressions. You'll stay in this repository for the next five videos, so it's worth learning its shape now.

Everything on screen comes from four replay scripts. The lab clock is fixed, so the commit IDs here are the ones in the book, and the ones you'll get when you replay the scripts.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

**[ON SCREEN]** After this video you can:

- describe a `git log` invocation as start points, exclusions, filters, format;
- filter history by author, message, date and path, and say which date is compared;
- show integrations only with `--first-parent`, and merges only with `--merges`;
- produce a custom one-line format and a per-author summary;
- explain why a date filter can omit commits from the named day.

## CONCEPT

**[ANIMATION]** graph: ...older-8e2cac1-b4b066b-4da82b5-389337a-8657273-...newer; ^8e2cac1-dd70d9e-c0d33a5-8657273; HEAD=none; title:Snapshots_and_parent_links,_nothing_else => + range:8e2cac1,b4b066b,4da82b5,389337a,dd70d9e,c0d33a5,8657273:8e2cac1~1..8657273; cmd:git_log_8e2cac1~1..8657273; say:Walked:_seven._Printed:_all_seven,_both_lines_and_the_merge; name:all; title:One_range,_three_questions => + range:8e2cac1,b4b066b,4da82b5,389337a,8657273:--first-parent; dim:dd70d9e,c0d33a5; cmd:git_log_--first-parent_8e2cac1~1..8657273; say:Stage_one:_the_walk_takes_the_first_parent,_389337a._Five_printed; name:first-parent => ...older-8e2cac1-b4b066b-4da82b5-389337a-8657273-...newer; ^8e2cac1-dd70d9e-c0d33a5-8657273; HEAD=none; range:8e2cac1,b4b066b,4da82b5,389337a,dd70d9e,c0d33a5,8657273:8e2cac1~1..8657273; mark:printed:8657273; cmd:git_log_--merges_8e2cac1~1..8657273; say:Stage_two:_seven_walked,_six_filtered_out,_one_printed; name:merges id=range

**[ANIMATION]** step: state-1

Start with why. History stores snapshots and parent links, nothing else. On screen: seven of today's commits and their links. Diffs, renames, "who wrote this line" and "which commit broke it" aren't recorded anywhere. Git computes them when you ask. So an investigation is a sequence of queries, and `git log` is the query engine for the first kind: queries over the graph.

**[ANIMATION]** end

In one sentence: 🟢 SAFE, `git log` walks the graph from the tips you name, filters the commits it meets, and prints each survivor in the format you choose. A tip is the commit that a branch, a name that moves forward as you commit, currently holds. It reads. It changes nothing.

Precisely, think in four stages, and place every option in one of them.

**[ON SCREEN]** The four-stage table from section 14A.9.

Stage one is the walk: which commits are visited. Revisions and ranges belong here, and so do `--all`, `--branches`, `--reflog`, `--first-parent` and `--ancestry-path`.

Stage two is the filter: which of the visited commits are shown. `--author`, `--committer`, `--grep`, `--since`, `--until`, `--merges`, `--no-merges`, the pickaxe options `-S` and `-G`, a path after two dashes, `--diff-filter`, and the count limit.

Stage three is the order: `--date-order`, `--topo-order`, `--author-date-order`, `--reverse`.

Stage four is the print: `--oneline`, `--format`, `--graph`, `--decorate`, `--stat`, `-p`, `--name-status`.

Try it now, on paper. Thirty seconds: take the command you already use most, `git log --graph --oneline --decorate --all`. Which stages do its options come from? Write your answer down.

**[PAUSE]**

It's one option from each of stages one, three and four. Walk from every ref. A ref is a name that holds a commit ID, such as a branch or a tag. Order topologically and draw the edges. Print one line per commit with the ref names.

**[ANIMATION]** gates: packet=git_log_--author=asha_-5 gates=walk:done:stage_1:from_HEAD|filter:done:stage_2:keep_Asha's_commits,_then_count_five|order:done:stage_3:commit_date,_newest_first|print:done:stage_4:one_entry_per_survivor title=Four_stages id=stages

**[ANIMATION]** step: 4

When to think this way: always, and say it out loud when you explain a query to a colleague. "`git log --author=asha -5`" is "walk from HEAD, keep Asha's commits, print the first five that pass". HEAD is Git's name for where you are now. The limit counts after the filter and before `--reverse`. That's why `--reverse -1` prints the newest commit and not the oldest. If you want the root commits, the ones without a parent, the textbook gives you `git rev-list --max-parents=0 HEAD`.

**[ANIMATION]** say: Wrong_tips,_a_filter_that_tests_something_else,_or_an_output_that_hides_a_distinction

When the model fails you, it fails in one of three places. You walked from the wrong tips, so the commit was never visited. Your filter tested something other than what you had in mind. Or the output hid a distinction, such as author versus committer. You'll see one example of each in the demonstration.

**[ANIMATION]** end

## MENTAL MODEL

**[ANIMATION]** walk: columns=stage,git_log,database_query rows=1:walk:FROM|2:filter:WHERE|3:order:ORDER_BY|4:print:SELECT title=A_query_over_the_graph id=query

**[ANIMATION]** step: 4

The textbook's analogy is a database query. `FROM` is the set of commits. `WHERE` is the filter. `ORDER BY` is the ordering. `SELECT` is the output format.

**[ANIMATION]** say: The_analogy_breaks_in_two_places

The analogy breaks in two places, and both matter in production.

**[ANIMATION]** say: No_index:_every_filter_scans_the_walked_commits

First, there's no index on authors or messages. Every filter is a scan of the walked commits. A filter never makes the walk smaller. Only stage one does that.

**[ANIMATION]** say: The_default_order_is_by_commit_date,_newest_first

Second, the default order is by commit date, newest first. Only `--topo-order`, which `--graph` implies, guarantees that no parent is printed before all of its children. If you read a plain `git log` as "this happened, then this", you're reading commit dates and not the graph.

**[ANIMATION]** say: walk,_filter,_order,_print

**[PAUSE]** Keep the four words on screen in mind: walk, filter, order, print. For every command in the rest of this video, name the stage of each option before you look at the output.

## DIAGRAM

**[ANIMATION]** step: range.all

**[DIAGRAM]** This is the part of the `scorekit` history with a side branch, drawn left to right, with the commit IDs of the transcript you are about to see. Build it in three passes.

```text
                 dd70d9e---c0d33a5          feat/text-utils (merged)
                /                  \
  ...---8e2cac1---b4b066b---4da82b5---389337a---8657273---...   main

  Invocation                                    Commits printed
  --------------------------------------------  ---------------------------------------------
  git log 8e2cac1~1..8657273                     all seven: both lines and the merge
  git log --first-parent 8e2cac1~1..8657273      8e2cac1 b4b066b 4da82b5 389337a 8657273
  git log --merges 8e2cac1~1..8657273            8657273 only
```

First pass: shade all seven commits. The range `8e2cac1~1..8657273` walks from the merge back to, and excluding, the parent of `8e2cac1`. A merge commit has more than one parent. Both parents of the merge are followed.

**[ANIMATION]** step: range.first-parent

Second pass: only the bottom row. `--first-parent` is a stage-one option. At the merge `8657273` the walk takes the first parent, `389337a`, the side that received the merge, and never visits the two commits of the side branch. On screen, those two go dark.

**[ANIMATION]** step: range.merges

Third pass: the merge alone. `--merges` is a stage-two option. All seven commits were walked, so all seven are shaded again. Six were filtered out because they have one parent, and only `8657273` is printed.

Same range, three questions, three answers. Two of the options changed the walk or the filter. None changed the repository.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch14a/history-tour`. The fixture is rebuilt from scratch, so nothing here depends on your own configuration.

Start with the symptom.

```bash
python3 -B -m scorekit.runner data/smoke.jsonl
git describe
```

Predict: what will the exit status of the runner be, given a pass mark and a score of 0.400?

<!-- snippet: ch14a/history-tour/01-symptom -->
```text
$ python3 -B -m scorekit.runner data/smoke.jsonl
rows=10 exact_match=0.400 token_f1=0.444 rouge_l=0.489
[exit status: 1]
$ git describe
v0.2.0-5-ge376e5b
```
<!-- /snippet -->

Point at the exit status 1: `exact_match` is below the pass mark. Then at `git describe`: the current commit is five commits after the tag `v0.2.0`. A tag is a name for a commit that isn't expected to move.

Now the whole history, with one option from each of stages one, three and four.

```bash
git log --graph --oneline --decorate --all
```

<!-- snippet: ch14a/history-tour/02-graph -->
```text
$ git log --graph --oneline --decorate --all
* e376e5b (HEAD -> main) Mention the nightly run in the README
* 2652768 Add a separate pass mark for the nightly set
| * a10f9a1 (feat/report) Write a report when --report <path> is given
| * f37a7d8 Mention the nightly run in the README
| * a8e8550 Add per-row report writer
|/  
* ca7e2b7 Fail fast on an empty reference
* d9d075d Remove the experimental BLEU scorer
* ec4fad7 Simplify token overlap in token_f1
* c0c9a30 (tag: v0.2.0) Add nightly evaluation set
* 7823232 Add ROUGE-L metric
| * 2f2883f (feat/rouge-l) Report ROUGE-L in the runner
| * 80ee55f Add ROUGE-L F-measure
| * 1cbe38a Add longest-common-subsequence helper
|/  
* 9c8df98 Reformat sources: four-space indent, double quotes
* d926d3c Speed up normalize with a precompiled pattern
* be9ad1b Fix crash when --limit is not given
* 074d492 Send warnings to stderr
* 8dc82cb Add --limit option to the runner
* 72134f3 Document the runner's exit status
*   8657273 Merge branch 'feat/text-utils'
|\  
| * c0d33a5 Add a tokens helper and use it in the metrics
| * dd70d9e Move normalize into scorekit/text.py
* | 389337a Raise the pass mark to 0.75
* | 4da82b5 Document the metrics
* | b4b066b Skip rows with an empty reference
|/  
* 8e2cac1 Strip punctuation before comparing
* 682bc71 (tag: v0.1.0) Add config module with the pass mark
* 18bb23e Rename the scorer module to metrics
* d38a5aa Move sources into the scorekit package
* d369eac Add experimental BLEU scorer
* 633e3e6 Add evaluation runner and smoke set
* bb5eb57 Add token-level F1 scorer
* b250238 Add exact-match scorer
* 5015359 Add project skeleton
```
<!-- /snippet -->

Read it from the bottom. Two tags, `v0.1.0` and `v0.2.0`. One true merge, `8657273`. Two branches that were never merged, `feat/rouge-l` and `feat/report`. Somewhere between `v0.1.0`, which the team knows scored correctly, and `main` there are twenty commits. You'll count them in a moment.

**[TERMINAL]** Replay `labs/run ch14a/log-graph`.

```bash
git log --graph --oneline 8e2cac1~1..8657273
```

<!-- snippet: ch14a/log-graph/01-graph-range -->
```text
$ git log --graph --oneline 8e2cac1~1..8657273
*   8657273 Merge branch 'feat/text-utils'
|\  
| * c0d33a5 Add a tokens helper and use it in the metrics
| * dd70d9e Move normalize into scorekit/text.py
* | 389337a Raise the pass mark to 0.75
* | 4da82b5 Document the metrics
* | b4b066b Skip rows with an empty reference
|/  
* 8e2cac1 Strip punctuation before comparing
```
<!-- /snippet -->

That's the diagram you saw, as Git draws it. Predict before the next command: with `--first-parent`, how many lines? Say it out loud. I'll wait.

**[PAUSE]**

```bash
git log --oneline --first-parent 8e2cac1~1..8657273
```

<!-- snippet: ch14a/log-graph/02-first-parent -->
```text
$ git log --oneline --first-parent 8e2cac1~1..8657273
8657273 Merge branch 'feat/text-utils'
389337a Raise the pass mark to 0.75
4da82b5 Document the metrics
b4b066b Skip rows with an empty reference
8e2cac1 Strip punctuation before comparing
```
<!-- /snippet -->

Five. On a branch that receives work through merges, this is the sequence of things that landed. The commits inside each landed branch are hidden.

```bash
git log --oneline --merges
git rev-list --count v0.1.0..main
git rev-list --count --first-parent v0.1.0..main
git rev-list --count --no-merges v0.1.0..main
```

<!-- snippet: ch14a/log-graph/03-merges -->
```text
$ git log --oneline --merges
8657273 Merge branch 'feat/text-utils'
$ git rev-list --count v0.1.0..main
20
$ git rev-list --count --first-parent v0.1.0..main
18
$ git rev-list --count --no-merges v0.1.0..main
19
```
<!-- /snippet -->

Twenty commits since `v0.1.0`. Eighteen on the first-parent line, because two arrived through the merge. Nineteen without the merge itself. Keep the number twenty. In the bisect videos it becomes the cost of a search.

For a repository you don't know, one more stage-two option gives you the outline.

```bash
git log --graph --oneline --decorate --simplify-by-decoration --all
```

<!-- snippet: ch14a/log-graph/04-decoration -->
```text
$ git log --graph --oneline --decorate --simplify-by-decoration --all
* e376e5b (HEAD -> main) Mention the nightly run in the README
| * a10f9a1 (feat/report) Write a report when --report <path> is given
|/  
* c0c9a30 (tag: v0.2.0) Add nightly evaluation set
| * 2f2883f (feat/rouge-l) Report ROUGE-L in the runner
|/  
* 682bc71 (tag: v0.1.0) Add config module with the pass mark
* 5015359 Add project skeleton
```
<!-- /snippet -->

Only the commits that a branch or tag points at remain.

**[TERMINAL]** Replay `labs/run ch14a/log-filters`. Now the filters, one kind at a time. By person first.

```bash
git log --oneline --author=Ravi
git log --format='%h %an (committed by %cn) %s' --author=Ravi --committer='Lab User'
```

<!-- snippet: ch14a/log-filters/01-author -->
```text
$ git log --oneline --author=Ravi
e376e5b Mention the nightly run in the README
d9d075d Remove the experimental BLEU scorer
d926d3c Speed up normalize with a precompiled pattern
074d492 Send warnings to stderr
8e2cac1 Strip punctuation before comparing
d369eac Add experimental BLEU scorer
$ git log --format='%h %an (committed by %cn) %s' --author=Ravi --committer='Lab User'
e376e5b Ravi Menon (committed by Lab User) Mention the nightly run in the README
```
<!-- /snippet -->

`--author` and `--committer` are regular expressions, patterns for matching text, matched against "Name, email in angle brackets". The second command asks for a commit written by one person and committed by another, and finds one: `e376e5b`. That's the cherry-pick. A cherry-pick copies one commit's change onto the current branch as a new commit. Remember it. It comes back when we look at dates.

By message.

```bash
git log --oneline --grep=crash
git log --oneline -i --grep=rouge
git log --oneline -i --grep=rouge --all
git log --oneline --grep=limit --grep=crash
git log --oneline --grep=limit --grep=crash --all-match
```

Predict two things. Does the second command find the commits on `feat/rouge-l`? And a quick quiz, two options: do two `--grep` options mean "and", or "or"? Say it out loud.

**[PAUSE]**

<!-- snippet: ch14a/log-filters/02-grep -->
```text
$ git log --oneline --grep=crash
be9ad1b Fix crash when --limit is not given
$ git log --oneline -i --grep=rouge
d9d075d Remove the experimental BLEU scorer
7823232 Add ROUGE-L metric
$ git log --oneline -i --grep=rouge --all
d9d075d Remove the experimental BLEU scorer
7823232 Add ROUGE-L metric
2f2883f Report ROUGE-L in the runner
80ee55f Add ROUGE-L F-measure
$ git log --oneline --grep=limit --grep=crash
be9ad1b Fix crash when --limit is not given
8dc82cb Add --limit option to the runner
$ git log --oneline --grep=limit --grep=crash --all-match
be9ad1b Fix crash when --limit is not given
```
<!-- /snippet -->

The quiz first: "or". Several `--grep` options are alternatives unless you add `--all-match`. And `--grep` searches messages, not content: the BLEU removal `d9d075d` is listed only because its message mentions ROUGE-L.

**[ANIMATION]** graph: ...older-9c8df98-7823232-c0c9a30-ec4fad7-d9d075d-ca7e2b7-2652768-e376e5b main; ^9c8df98-1cbe38a-80ee55f-2f2883f feat/rouge-l; ca7e2b7-a8e8550-f37a7d8-a10f9a1 feat/report; HEAD=main; title:Which_commits_did_the_filter_see? => + range:9c8df98,7823232,c0c9a30,ec4fad7,d9d075d,ca7e2b7,2652768,e376e5b,...older:walked_from_HEAD; dim:1cbe38a,80ee55f,2f2883f,a8e8550,f37a7d8,a10f9a1; mark:match:7823232,d9d075d; cmd:git_log_-i_--grep=rouge; say:Stage_one:_the_walk_starts_at_HEAD;name:head => ...older-9c8df98-7823232-c0c9a30-ec4fad7-d9d075d-ca7e2b7-2652768-e376e5b main; ^9c8df98-1cbe38a-80ee55f-2f2883f feat/rouge-l; ca7e2b7-a8e8550-f37a7d8-a10f9a1 feat/report; HEAD=main; mark:match:7823232,d9d075d,80ee55f,2f2883f; cmd:git_log_-i_--grep=rouge_--all; say:With_--all_the_walk_starts_at_every_ref;name:all id=grep

And the first prediction: no. Without `--all` the walk starts at HEAD, so commits that exist only on other branches aren't searched. That's a stage-one mistake that looks like a stage-two result. With `--all`, two commits on `feat/rouge-l` match as well.

**[ANIMATION]** end

By date.

```bash
git log --oneline --since='2026-09-10 00:00' --until='2026-09-11 00:00'
git log --oneline --since='2 days ago'
```

<!-- snippet: ch14a/log-filters/03-dates -->
```text
$ git log --oneline --since='2026-09-10 00:00' --until='2026-09-11 00:00'
d926d3c Speed up normalize with a precompiled pattern
be9ad1b Fix crash when --limit is not given
074d492 Send warnings to stderr
8dc82cb Add --limit option to the runner
72134f3 Document the runner's exit status
$ git log --oneline --since='2 days ago'
e376e5b Mention the nightly run in the README
2652768 Add a separate pass mark for the nightly set
ca7e2b7 Fail fast on an empty reference
d9d075d Remove the experimental BLEU scorer
ec4fad7 Simplify token overlap in token_f1
```
<!-- /snippet -->

Five commits on the tenth, with full timestamps in the query. Dates have two traps. The first: `--since` and `--until` test the committer date, the time the commit object was created, not the author date.

```bash
git log --format='%h authored %ad, committed %cd' --date=format:'%a %H:%M' --since='2026-09-15 12:30'
```

<!-- snippet: ch14a/log-filters/04-committer-date -->
```text
# --since and --until test the committer date. The newest commit was authored at 10:46 and committed at 12:41:
$ git log --format='%h authored %ad, committed %cd' --date=format:'%a %H:%M' --since='2026-09-15 12:30'
e376e5b authored Tue 10:46, committed Tue 12:41
```
<!-- /snippet -->

`e376e5b` was authored at 10:46 and committed at 12:41. It passes a filter of "since 12:30" because the committer date is compared. A cherry-picked commit, or a rebased one, which is also a new copy, carries its old author date and a new committer date.

**[ANIMATION]** graph: ...older-72134f3-8dc82cb-074d492-be9ad1b-d926d3c-9c8df98-...newer; HEAD=none; sub:72134f3:Thu_10:06; sub:8dc82cb:Thu_10:41; sub:074d492:Thu_11:36; sub:be9ad1b:Thu_12:31; sub:d926d3c:Thu_13:36; sub:9c8df98:Fri_10:16; title:The_tenth_of_September => + range:72134f3,8dc82cb,074d492,be9ad1b,d926d3c:Thu_00:00_to_Fri_00:00; cmd:git_log_--since='2026-09-10_00:00'_--until='2026-09-11_00:00'; say:Five_commits_on_the_tenth; name:full => + range:d926d3c,9c8df98:Thu_12:51_to_Fri_12:51; cmd:git_log_--since=2026-09-10_--until=2026-09-11; say:No_time_given:_the_clock's_12:51_is_used._The_window_slides; name:slid id=window

**[ANIMATION]** step: state-1

Now stop. This is the snippet the video is built around. The lab clock reads 12:51.

**[ANIMATION]** step: full

You want the commits of the tenth of September, and you write the dates without a time. You saw five commits a minute ago. Predict what this prints.

**[PAUSE]**

```bash
git log --oneline --since=2026-09-10 --until=2026-09-11
```

<!-- snippet: ch14a/log-filters/03b-time-of-day -->
```text
# A date without a time takes the current time of day. The lab clock reads 12:51.
$ git log --oneline --since=2026-09-10 --until=2026-09-11
9c8df98 Reformat sources: four-space indent, double quotes
d926d3c Speed up normalize with a precompiled pattern
```
<!-- /snippet -->

Two commits, and one of them, `9c8df98`, was made on the morning of the eleventh. Four commits from the morning of the tenth are missing. There's the missing morning.

**[ANIMATION]** step: window.slid

Here it is as a picture. With no time given, the window runs from 12:51 on the tenth to 12:51 on the eleventh. Watch it slide.

**[ANIMATION]** end

**[ON SCREEN]** The root-cause box of section 14A.9, one line at a time.

```text
Observed behavior : --since=2026-09-10 --until=2026-09-11 omits four commits made on the morning of the 10th
                    and includes one made on the morning of the 11th
Git state         : nothing unusual; the commits exist and carry those dates
Mechanism         : Git's date parser took the time of day, which the argument left out, from the clock
Root cause        : "2026-09-10" was read as "10 September at the present time of day", here 12:51
Why Git does this : the same parser serves "yesterday" and "2 days ago", which are meant relative to now;
                    the manual notes only that "today" means the last midnight
Correct fix       : write the time: --since='2026-09-10 00:00' --until='2026-09-11 00:00'
Prevention        : in scripts and incident notes always give a full timestamp, and state the time zone
```

And the caveat, exactly as the textbook states it: this behavior was observed on Git 2.55.0, in the transcript you have on screen. The manual page of `git log` doesn't describe it. Almost everyone gets this wrong the first time.

There's a third property of `--since`. It stops the walk at the first commit that is too old. In a history whose commit dates aren't in order, for example after an import or with a wrong clock, an old-looking commit can hide newer ones behind it. `--since-as-filter` visits the whole range instead.

By path.

```bash
git log --oneline -- scorekit/config.py
git log --oneline v0.2.0..main -- docs scorekit/metrics.py
```

<!-- snippet: ch14a/log-filters/05-paths -->
```text
$ git log --oneline -- scorekit/config.py
2652768 Add a separate pass mark for the nightly set
389337a Raise the pass mark to 0.75
682bc71 Add config module with the pass mark
$ git log --oneline v0.2.0..main -- docs scorekit/metrics.py
d9d075d Remove the experimental BLEU scorer
ec4fad7 Simplify token overlap in token_f1
```
<!-- /snippet -->

`git log -- <path>` shows the commits whose version of the path differs from their parent's. With merges in the history, the default mode also prunes side branches that didn't contribute to the final content, so a change that was made and later undone on a branch may not appear. `--full-history` disables that pruning. Adding `--stat` or `-p` prints the summary or the patch, and with a path only that path's part.

```bash
git log --stat --format='%h %s' -2 -- scorekit/config.py
git log -p --format='%h %s' -1 -- scorekit/config.py
```

<!-- snippet: ch14a/log-filters/06-stat-patch -->
```text
$ git log --stat --format='%h %s' -2 -- scorekit/config.py
2652768 Add a separate pass mark for the nightly set

 scorekit/config.py | 1 +
 1 file changed, 1 insertion(+)
389337a Raise the pass mark to 0.75

 scorekit/config.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git log -p --format='%h %s' -1 -- scorekit/config.py
2652768 Add a separate pass mark for the nightly set

diff --git a/scorekit/config.py b/scorekit/config.py
index 5efef40..12c95c2 100644
--- a/scorekit/config.py
+++ b/scorekit/config.py
@@ -1,2 +1,3 @@
 # Thresholds used by the runner.
 PASS_MARK = 0.75
+NIGHTLY_PASS_MARK = 0.6
```
<!-- /snippet -->

**[TERMINAL]** Replay `labs/run ch14a/log-formats`. The last stage: print.

```bash
git log -4 --format='%h %ad %<(10,trunc)%an %s' --date=short
git log -3 --format='%h %ar%x09%s'
```

<!-- snippet: ch14a/log-formats/01-format -->
```text
$ git log -4 --format='%h %ad %<(10,trunc)%an %s' --date=short
e376e5b 2026-09-15 Ravi Menon Mention the nightly run in the README
2652768 2026-09-15 Lab User   Add a separate pass mark for the nightly set
ca7e2b7 2026-09-14 Asha Rao   Fail fast on an empty reference
d9d075d 2026-09-14 Ravi Menon Remove the experimental BLEU scorer
$ git log -3 --format='%h %ar%x09%s'
e376e5b 2 hours ago	Mention the nightly run in the README
2652768 32 minutes ago	Add a separate pass mark for the nightly set
ca7e2b7 22 hours ago	Fail fast on an empty reference
```
<!-- /snippet -->

Abbreviated ID, short author date, the author padded and truncated to ten columns, the subject. This one-line format answers most "who and when" questions at a glance. In the second command look at the relative dates: `e376e5b` says two hours ago and the commit below it says 32 minutes ago. That's the author date of the cherry-pick again. Relative dates are computed from the clock at the moment you run the command, so paste absolute dates into a report.

Trailers carry attribution that the author field can't. A trailer is a key and value line in the last paragraph of a commit message.

```bash
git log -1 --format='%h %s%n  author: %an%n  with:   %(trailers:key=Co-authored-by,valueonly,separator=%x2C )' 7823232
```

<!-- snippet: ch14a/log-formats/03-trailers -->
```text
$ git log -1 --format='%h %s%n  author: %an%n  with:   %(trailers:key=Co-authored-by,valueonly,separator=%x2C )' 7823232
7823232 Add ROUGE-L metric
  author: Lab User
  with:   Asha Rao <asha@example.com>, Ravi Menon <ravi@example.com>
```
<!-- /snippet -->

`7823232` is a squash merge: several commits combined into one new commit. One author field, two people in the trailers.

```bash
git shortlog -sn HEAD
git shortlog -sn --no-merges --group=author --group=trailer:co-authored-by HEAD
```

<!-- snippet: ch14a/log-formats/04-shortlog -->
```text
$ git shortlog -sn HEAD
    14	Lab User
     8	Asha Rao
     6	Ravi Menon
$ git shortlog -sn --no-merges --group=author --group=trailer:co-authored-by HEAD
    13	Lab User
     9	Asha Rao
     7	Ravi Menon
```
<!-- /snippet -->

`-s` counts, `-n` sorts by count. The second form adds the `Co-authored-by` trailer as a second grouping key, so Asha and Ravi are credited for the squashed commit as well. Without `-s`, shortlog over a range is a draft of release notes. You'll produce one in the exercise.

One last command, and a prediction. Standard input isn't a terminal here. What does `git shortlog -sn` print with no revision?

```bash
git shortlog -sn < /dev/null
git log v0.2.0..main | git shortlog -sn
```

<!-- snippet: ch14a/log-formats/06-shortlog-stdin -->
```text
# Without a revision, and with standard input that is not a terminal, shortlog reads a log from standard input:
$ git shortlog -sn < /dev/null
$ git log v0.2.0..main | git shortlog -sn
     2	Asha Rao
     2	Ravi Menon
     1	Lab User
```
<!-- /snippet -->

Nothing. In that situation shortlog reads a log from standard input instead of walking from HEAD. In a script, a hook or a CI job, where no person is typing, always pass the revision.

## COMMON MISTAKES

Five mistakes to watch for.

**[ON SCREEN]** Five mistakes, each with its root cause.

1. **A date filter that drops the morning.** Root cause: a date without a time takes the present time of day from the clock, so `--since=2026-09-10` meant the tenth at 12:51.
2. **"It was committed on Tuesday, why does the filter not find it?"** Root cause: `--since` and `--until` compare the committer date, and a cherry-pick or rebase gives a commit a new committer date while keeping the author date.
3. **A search that misses commits on other branches.** Root cause: without `--all` the walk starts at HEAD; the filter never saw the commits.
4. **`git log -- path` omits a change you know was made.** Root cause: with merges in the history the default path mode prunes side branches that did not contribute to the final content; `--full-history` disables the pruning.
5. **A CI job whose `git shortlog` prints nothing.** Root cause: with no revision and a standard input that is not a terminal, shortlog reads a log from standard input.

A sixth, for judgement and not for Git: commit counts measure commits. They say nothing about the size or the value of the work, and a squash-merge workflow moves the counts to whoever presses the merge button.

## PRODUCTION EXAMPLE

**[ANIMATION]** step: window.slid

Now, out of the lab. An evaluation team writes an incident note: "No commits touched the harness on 10 September." The engineer ran the date query at lunchtime without a time of day. Four commits from that morning weren't listed, and one of them changed how warnings are sent.

**[ANIMATION]** graph: ...older-72134f3-8dc82cb-074d492-be9ad1b-d926d3c-9c8df98-...newer; HEAD=none; sub:72134f3:Thu_10:06; sub:8dc82cb:Thu_10:41; sub:074d492:Thu_11:36; sub:be9ad1b:Thu_12:31; sub:d926d3c:Thu_13:36; sub:9c8df98:Fri_10:16; range:72134f3,8dc82cb,074d492,be9ad1b,d926d3c:Thu_00:00_to_Fri_00:00; cmd:git_log_--since='2026-09-10_00:00'_--until='2026-09-11_00:00'; say:The_corrected_note:_a_full_timestamp_at_each_end,_and_the_time_zone; title:The_tenth_of_September id=corrected at_state_1=8

The corrected note states the query as it was run: the range, a full timestamp at each end, and the time zone. It also says which date was compared: the committer date. Anyone who reads the note can rerun the command and get the same list, whatever the time of day. That's the standard for evidence in the rest of this course: the command, written so that it's reproducible, beside the claim.

**[ANIMATION]** end

## PRACTICE EXERCISE

Your turn. Do Exercise 11.6, Level 2, "Release notes from history", in [`exercises/m11-m15-investigation-recovery.md`](../../exercises/m11-m15-investigation-recovery.md).

You produce three things for a release, each with one command: a list of changes since `v0.2.0`, oldest first, without merges; the number of those commits per author; and the same range as a reviewer of `main` would read it.

Before you type anything, predict: will the first list have more lines than the third has non-merge lines, and if so, which commits make the difference? Write the answer down, then run the commands. Work in `labs/shell`. The commit IDs there differ from the book because the clock is real.

The challenge is Exercise 11.10, Level 4, "It is fixed in 2.3", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q411: "`git log --since=2026-09-10` omitted commits from the morning of that day. Explain the cause and state how you would write the query in an incident report."

Pause the video and answer out loud before you continue.

**[PAUSE]**

A strong answer does four things. It names the mechanism, not the symptom: what the date parser does with a missing time of day. It says which of the two dates of a commit the filter compares, and why that matters after a cherry-pick or a rebase. It gives the corrected query in a form that returns the same result at any time of day. And it's honest about the evidence: where this behavior was observed and what the manual does and doesn't say. If you also mention when `--since` stops walking, and the option that changes that, you have covered the section.

## RECAP

Let's land this. You should now be able to say:

- `git log` walks from the tips I name, filters what it meets, orders it, and prints it; every option belongs to one of those four stages.
- `--first-parent` changes the walk and shows what landed on a branch; `--merges` and `--no-merges` filter by parent count.
- `--since` and `--until` compare the committer date, and a date without a time takes the present time of day.
- Without `--all`, a filter never sees commits that only other branches reach.
- In a script I pass a revision to `git shortlog`, and in a report I write absolute timestamps with a time zone.

## HOMEWORK

Read sections 14A.9 and 14A.15 of [Chapter 14A](../../textbook/ch14a-history-investigation.md). As you read, replay `labs/run ch14a/log-filters` and, for each command, name the stage of every option before you look at the output.

**[ANIMATION]** replay: stages

Today `git log` became a query with four stages, and you can explain where a missing morning went. Replay the filters before the next video. Next time: set questions, `git grep`, and the retirement of `git whatchanged`. Until then, look at the state first and type second. See you in the next one.
