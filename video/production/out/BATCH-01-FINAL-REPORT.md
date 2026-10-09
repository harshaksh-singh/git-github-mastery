# Batch 1, first part (V001 to V009, V020, V022, V025): final inspection report

Written 2026-10-09 by the finishing inspector of these twelve videos, after all of them had been voiced again with the repaired voice step (V001 to V009 by the second voice run at 09:14 to 09:38, V020, V022 and V025 by the automatic final pass at 10:51 to 10:57). Voice: the macOS voice Tara at 165 words per minute. The form follows `BATCH-01-02-FINAL-REPORT.md`, which covers the rest of batches 1 and 2.

## 1. Result

- **12 of 12 videos built, 12 of 12 PASS from the QC tool** (`make.sh qc V001-V009 V020 V022 V025`, run at 12:57 after the last build): 1920x1080, 30/1 fps, H.264 and AAC, built from the script as it is now (script SHA-1 of every storyboard and build equals the script on disk), storyboards with no warning and no hint. Loudness -16.1 LUFS and true peak -1.6 to -2.0 dBTP in all twelve. Warnings: subtitle line length (E5) and reading speed (E6) in every video; **one pace warning** (C2, three identical takes) in V005 (section 7). No other C1 or C2 warning.
- Total length 3 h 12 min, 0.84 GB. Files: `video/production/out/VNNN.mp4` with `.srt`, `.chapters.txt`, `.build.json`; QC reports in `video/production/out/qc/`.
- **At the start** (12:02): all twelve passed QC with the same warnings.
- **9 videos were rebuilt in full**, one at a time from a detached queue started from a fresh shell with `setopt NO_BG_NICE` (storyboard, slides, animate under `nice -n 20`; voice at normal priority; QC niced), 12:15 to 12:56: V002, V003, V004, V006, V005, V007, V020, V008 (twice, see V008), V025. **Every voice build succeeded at the first attempt; no sentence was refused.**
- **Not rebuilt:** V001, V009, V022 (nothing to fix).
- **How they were inspected.** Frames of the finished MP4s, laid out as captioned contact sheets (time, beat, section, slide kind and the sentence being read under each frame): the last moment of every paragraph read over a scene, table, drawing or callout; the middle of every scene paragraph over 20 s and of every paragraph over 30 s; every pause and every silent hold (middle); the frame just before every pause; the end of every paragraph that asks a question; six spread over the length. 38 to 61 frames per video, 570 in all, plus full-size crops of five graphs. Plus scans by script: headlines inherited from an earlier bold lead-in, silent holds, on-screen directions and how each is drawn, caveat words, and the text given to the voice (`.cache/tts/VNNN.spoken.txt`) for director notes. After each rebuild the changed places were looked at again in the new MP4 (3 to 11 frames each, 67 in all); the unchanged parts of a rebuilt video were not looked at a second time.
- **Not done: nobody listened.** No audio was heard at any point. Section 7 lists what was done for the sound.

"Explainer scenes" is the share of running time during which a library scene (including the animated commit graph) is on screen, measured from the storyboard and the beat times. "Silent" means on screen with no sentence read over it. All times are from the final builds.

## 2. Per video

| Video | Length | Size | Explainer scenes | QC tool | What was fixed | Still imperfect |
|---|---|---|---|---|---|---|
| **V001** How this course works | 18:49 | 90 MB | 19 % | PASS | Nothing changed. | The hash scene "why the clock is fixed" (5:42 to 6:24) shows the library's sample second commit (an ID and the date "Tue 8 Sep 15:42" that the script does not print; `tools/check_course.py` confirms the ID is in no transcript); the first one (`c672627`, Mon 7 Sep 10:07) is the script's. The trees scene (7:14) shows a HEAD chip with `c1`. |
| **V002** What version control solves; Git and GitHub | 19:11 | 86 MB | 13 % | PASS | (1) Goals table 1.4: one row was highlighted per paragraph, so "Simple design", "Strong support for non-linear development" and "Able to handle large projects" were read while their rows were dimmed. The paragraph is split in five, one per row (5:44 to 6:22); no word changed. (2) The Git/GitHub table of section 1.5 stood 12 s in silence in the DIAGRAM section, two pages of 6 s: one sentence per page, made of the table's cells (11:40 to 11:57). | In the mental model the remotes scene keeps the caption "Asha pushes commit C" under the library analogy (10:22). The pull-request scene shows the library's "#42", "Check: tests", "Check: lint" (9:33 to 9:49, 18:20). |
| **V003** A first repository, read file by file | 15:52 | 70 MB | 12 % | PASS | (1) The strip of three boxes stood 5.8 s silent: one sentence from its labels (4:57). (2) `06-second-commit`: page 1 (`git status`, "Changes not staged") stood 3 s silent and its sentence was read over page 2: the paragraph is split at "`git diff` shows" (9:42 to 10:03; ", and" removed). (3) `02-read`: "`info/exclude` ... a sample hook" was read over page 1 and page 2 flashed for 3 s afterwards: paragraph split (11:45 to 12:10). (4) Headline "Step 5: a second commit" over "One more replay": that sentence is a bold lead-in now (11:24). | `01-init` pages 1 and 2 of 3 stand 3 s each in silence (11:33 to 11:39; library #4). |
| **V004** The root-cause framework | 13:33 | 57 MB | 9 % | PASS | (1) The three drawings of the DIAGRAM section stood 22.7 s in silence: "Here's the whole method on one page." now stands under the first, and one sentence from its own labels under the second and the third (6:28 to 6:46). (2) Headline "Prevent" over "Two rules make the framework safe" and its three paragraphs, and "Prevention" over "Notice what did the work" and the layer quiz (batch 1 report: "a headline can outlive its topic"): the three opening sentences are bold lead-ins now (3:51, 8:59, 9:18); no word changed. | The trees scene shows a HEAD chip without `main`. Explainer share 9 %. |
| **V005** The ten-command diagnosis | 15:13 | 67 MB | 9 % | PASS; warn C2 | Headline "11. What does Git track?" over "Eleven lines, and nothing in the repository has changed ... allowed a theory": bold lead-in (10:26). | Pace warning: section 7. In the graph at 7:50 the diagonal edge starts at the last digit of `25fbbb0` (readable). The remotes scenes use the letters A to C. |
| **V006** Worked example: the fix that did not ship | 15:15 | 68 MB | 14 % | PASS | (1) **Answer before its question:** the root-cause box of section 1.12 stood 8.2 s silent in the DIAGRAM section, one minute before "write the root cause in one sentence ... compare your answer with the box"; the later "Show the root-cause box now" drew nothing. `step: state-1` now puts the commit graph in its place with one sentence (6:20), and the try-it ends "compare your answer with mine" (7:19). (2) Headlines "Test the hypotheses" over "Root cause", "Prevent" over the CTO's three questions and over the first-day pitfalls: bold lead-ins (7:31, 8:56, 9:11). | The root-cause box is no longer drawn (the library cannot bring a drawing back; its root cause is read at 7:31). The `[ON SCREEN]` state table for `git push` (script line 185) is not drawn, as before. |
| **V007** Snapshots, not diffs, and content addressing | 16:30 | 77 MB | 24 % | PASS | Table 2.4: the highlight ran one row behind the narration, the Commit row was dimmed while read. Paragraph split in three (4:39 to 5:13); no word changed. | The hash scenes show the library's sample values (the second ID of the "one byte differs" pair is in no transcript; "shelf 7e4a" and "shelf 2f9b" in the warehouse picture). The quiz "how many of the three blob IDs will be new?" (9:22) is recall of the DIAGRAM scene two minutes earlier. |
| **V008** The four object types, and a commit built by hand | 16:17 | 73 MB | 9 % | PASS | (1) **Garbled table:** the "five-rung ladder" drawing was drawn as a table with all five rows merged into one ("1 2 3 4 5", the commands run together) and stood 5 s silent. A `walk` scene with the same five rows (look `b1f-v008`, clean) replaces it, with one sentence (7:20). (2) The state table 2.6, two pages of 3.8 s, was never read: three short sentences from its cells (12:17 to 12:36). Rebuilt twice: in the first build `git update-ref` was read while its row was dimmed; the sentence is its own paragraph now. | The last rung of the ladder is complete for only 0.3 s before the section card (7:25.6). Explainer share 9 %. |
| **V009** The commit graph, reachability, refs and HEAD | 16:00 | 69 MB | 20 % | PASS | Nothing changed. | In the section 2.7 graph the diagonal edges pass the ends of `0fd50fb` and `2511274` (6:32 to 6:55; readable; batch 1 report). "Where is it now?" (8:40) is asked over the transcript whose `git cat-file -t` line already says `commit`. |
| **V020** Author and committer, two dates, and parents | 16:30 | 69 MB | 8 % | PASS | (1) Table 6.5: while the row "`git cherry-pick`, `git rebase`, `git commit --amend`" was read (17 s), the row "`git commit`" was highlighted and the row being read was dimmed. A lead-in "Three share one row:" stops the false match; all rows are lit (2:52 to 3:11). (2) `01-cherry-pick` page 1 (Asha's own commit) stood 3 s silent while it typed: one sentence from the transcript (8:44). (3) `05-log-basics` stood 8 s silent at the end of the demo: one sentence naming its four commands (12:05). | The added sentence over the GitHub note is read with the note on screen (5:12), but the note shows only the quotation: the rest of the direction ("Nothing in that match proves ...") is not drawn (library #1); "That match doesn't prove who made the commit" is read. Column head "COMMITTE / R" wraps inside the word (2:40 to 3:26). Two 3 s page holds (9:32, 11:32; library #4). Explainer share 8 %. |
| **V022** A branch is a ref, HEAD is a symbolic ref | 14:04 | 58 MB | 25 % | PASS | Nothing changed. | The state table with the added sentence is on screen 5.6 s for seven rows (5:28). `02-commit` stands 4 s silent after the try-it pause (10:05). |
| **V025** Divergence, ancestry, no parent branch | 15:09 | 61 MB | 27 % | PASS | (1) Table 7.8: the row `A..B` was highlighted and `A...B` dimmed for the whole paragraph that reads both. A lead-in "Read the table one column at a time." stops the row match (3:04 to 3:26). (2) **GitHub note cut in the middle** (4:50): the callout ends "It is the one place where" followed by the quotation "created from"; the rest of the direction is not drawn. The narration now completes it: "It's the one place where "created from" is recorded." | The callout itself is still cut (library #1; the direction may not be changed), and its last sentence ("GitHub computes a pull request's changes from a merge base too") is neither shown nor read. The remotes scene uses the letters A to C. |

### Imperfections that apply to several videos

1. **Tables whose highlight does not follow the narration** (new with the repaired timing: a table row is highlighted per paragraph): V002, V007, V020, V025: fixed by paragraph splits or a lead-in. The same splits brought paged transcripts into step in V003.
2. **Drawings, tables and transcripts held in silence**: V002 (12 s), V003 (5.8 s and two pages), V004 (22.7 s), V006 (8.2 s), V008 (5 s and 7.6 s), V020 (3 s and 8 s): each now has a sentence made of its own cells or labels, or a scene in its place. Left: 3 s page holds in V003 and V020 (library #4), 4 s in V022.
3. **Stale headlines** (a key point keeps the headline of the last bold lead-in): V003, V004, V005, V006: fixed by making the first sentence of the paragraph a bold lead-in (no word changed). Other inherited headlines were looked at and fit their paragraph.
4. **Answers on screen before their question**: V006 only (root-cause box); fixed.
5. **Library sample values** in the `hash`, `pr`, `trees` and `remotes` scenes (IDs, "#42", `c1`, letters A to C) where the script prints none: left; they are illustrations, and the narration does not call them real.
6. **Explainer share**: 8 % (V020) to 27 % (V025); V003 to V006, V008 and V020 are carried by transcripts and tables, as the batch 1 report says.

## 3. Answers and causes (H3, H4)

| Video | Question | What the screen shows before it |
|---|---|---|
| V006 | "Write the root cause in one sentence" (7:19) | Before: the root-cause box at 6:20, one minute earlier. Now: the commit graph there, the test transcript during the pause, the root cause after it (7:31). |
| V003 | "HEAD changed, or the branch file changed?" (10:13) | A key point; the three-boxes scene before it says "commit records the index as a new snapshot" and names no ref (batch 1 fix, still in place). |
| V007 | "How many of the three blob IDs will be new?" (9:22) | The first listing only. The DIAGRAM scene showed "one new ID" at 7:45 (recall, by design). |
| V009 | "Where is it now?" (8:40) | The transcript with `git cat-file -t` → `commit` (part of the answer; the count and `fsck` lines arrive after the pause). |
| V020 | "Who is the author after a rebase?" (3:26) | A key point; the table has left (batch 1 fix, still in place). |
| V025 | Merge base and counts (7:56), three exit statuses (8:36), dots quiz (9:01), "where is `feature/rouge` recorded" (9:28) | The graph transcript without counts; the count transcript; the ancestor transcript; the `labs/run` card. None shows its answer. |
| All others | every pause and every interview question | Frames of every pause and of the moment before it were looked at: no answer on screen. Every interview section holds only the question card. |

V006 is a worked incident: with the box moved, nothing names the root cause before the test (H4).

## 4. Fix-list and final-pass items

| Item | Outcome |
|---|---|
| V001 to V009 voiced again after the loud-take and inner-silence checks (7 Oct 16:45) | **Closed**: built 9 Oct 09:14 to 09:38 (six of them again by this pass); B4 and C2 PASS, including V007. |
| V004 built by the old builder | **Closed**: I6 PASS. |
| V001 to V003 older peak level | **Closed**: true peak -1.9, -2.0, -2.0 dBTP. |
| V009 to voice again (bad mark removed) | **Closed**: C2 PASS. |
| V020 failed QC after its voice step | **Closed**: PASS. |
| V020, V022, V025: one narration sentence added over an on-screen note | **Checked in frames**: read with the note on screen (V020 5:12, V022 5:28, V025 4:50). V025's note is cut by the library; its sentence was extended (section 2). |
| All ranges: no diagram held in silence | **Closed** for these twelve (section 2); 3 s page holds left. |
| All ranges: contraction passes, spot-check subtitles | Done by scan: no `**`, backtick, bracket tag or director note in any `.srt`; placeholders such as `<path>` appear as in the commands. Coverage 100 % (E8). |
| All ranges: one wording per term | **Open** (glossary pass). |
| Clips accepted under the three-takes rule | One: V005 at 2:06 (section 7). |

## 5. Other things corrected

- After each edit `python3 tools/inject.py --check` reported 0 problems for the script, and `python3 tools/check_course.py` reports 0 problems (704 files) after each build and at the end.
- Narration growth (paragraph words): V008 2.5 %, V004 2.0 %, V020 1.9 %, V002 1.7 %, V003 1.4 %, V006 0.8 %, V025 0.8 %; V005 and V007 unchanged in count; V001, V009, V022 untouched. No fact was added: every new sentence is made of the cells of the table, the labels of the drawing or the lines of the transcript on screen, or of the on-screen direction it is read over (V025).
- Changed: `[ANIMATION]` lines (V006 one `step: state-1`; V008 one `walk` tag and one `end`), the narration sentences named in section 2, paragraph splits, and bold lead-in marks on existing sentences (V003, V004, V005, V006). No snippet, table, heading, `[PAUSE]` or on-screen direction was touched. Nothing in `tools/` was edited.
- Every edited script was storyboarded in a scratch sandbox first (0 warnings, 0 hints). Each edit was kept outside `video/scripts/` until its build started and was copied in by the queue. The scripts as they were before this pass: `video/production/.cache/inspect-b1f/orig/`.

## 6. What was verified by looking, and what was not

Verified in frames of the finished videos: every item in the "What was fixed" column, in the rebuilt MP4; that no quiz, prediction, try-it or interview question is asked over, or followed within its pause by, a picture that shows its answer, at the sampled moments (V009 8:40 is the partial exception listed); the absence of overlapping or cut text and of literal underscores at the sampled moments, except where listed; that every risk label seen stands with its command; that IDs, paths and branch names in the graphs are those of the transcripts.

Not verified: frames between the samples; the unchanged parts of a rebuilt video after its rebuild; the audio; the subtitles beyond the scans and the QC tool's checks; checklist items A13, C6, C7, E9 (need ears or a player), F9, F10, G4, G5 and I8 to I10 (player, chapter clicks, thumbnails, upload).

## 7. The sound (not listened to)

Nobody listened to any of the twelve videos. What could be established without ears:

- `make.sh qc`: all PASS. Loudness, peak, clipping, silence and the pace of every beat are inside the tool's bounds or accepted under the three-identical-takes rule; every clip has its verification mark.
- **Clip accepted under the three-identical-takes rule, to be listened to once:**

| Video | Time | Sentence | Measured |
|---|---|---|---|
| V005 | 2:06 | "State before hypothesis. The framework says: understand the state, then form hypotheses. ..." (one part of this beat was accepted under the rule) | 2.60 words/s, 12.3 letters/s |

- **Places worth one listen** although the tool does not flag them (sentences of this pass, spoken for the first time):
  - **V020, 12:05**: "`--oneline -3`, `-1 --stat`, a format with `--no-merges`, and a path after two dashes" (options with digits); **2:52**: "Three share one row: git cherry-pick, git rebase, git commit --amend."
  - **V008, 12:17 to 12:36**: `git hash-object -w`, `git update-index`, `git write-tree`, `git commit-tree`, `git update-ref` in short sentences; **7:20**.
  - **V002, 11:40 to 11:57**: the two table sentences ("The "Verified" badge and a pull request don't."); **5:44**: the one-sentence clip "Speed: almost every operation reads local files."
  - **V025, 4:50**: "It's the one place where "created from" is recorded."; **3:04**.
  - **V003, 4:57** (`git add`, `git commit`) and **11:53** ("`info/exclude`: comments only.").
  - **V004, 6:30 to 6:46**, and **V006, 6:20** and **7:31** ("Root cause." as its own sentence).
- The voice builds: ten builds, each at the first attempt.
- The text given to the voice was scanned for presenter notes: none found. "On screen ..." and "Twig looks worried" in the range are addressed to the viewer.

## 8. Library defects and limits found (nothing in `tools/` was edited)

Numbers follow section 8 of `BATCH-01-02-FINAL-REPORT.md` where the defect is the same.

| # | Where seen | Defect | Workaround used |
|---|---|---|---|
| 1 | V025 4:50, V020 5:12 | A `Lower third: **GitHub**. ...` direction that contains a quotation is drawn as label, quotation, and nothing after it: V025's callout stops in the middle of a sentence ("It is the one place where" / "created from"), V020's loses its three closing sentences. | V025: the narration completes the sentence |
| 4 | V003 11:33, V020 9:32 and 11:32; V020 2:40 | A page of a paged transcript with no paragraph of its own stands 3 s in silence; a narrow column head wraps inside a word ("COMMITTE / R"). | paragraph splits and one-sentence paragraphs where possible |
| 7 | V008 (before the fix) | A `text` fence drawn as a table merges all its rows into one when the lines are adjacent (the five-rung ladder). | a `walk` scene in its place |
| 10 | V006 | A `[DIAGRAM] Show the root-cause box now.` direction after the demo draws nothing. | the root cause is read over a key point |
| 11 | V002, V007, V020, V025 | A table row is highlighted, and the others dimmed, for a whole paragraph on the strength of the first row named in its first eight words; a paragraph that reads several rows, or a row whose first cell is longer than 40 characters, leaves the row being read dimmed. | one paragraph per row, or a lead-in sentence that moves the row name out of the first eight words |
| 12 | V003 to V006 | A key point keeps the headline of the last bold lead-in until the next one (batch 1 report). | bold lead-in on the paragraph's own first sentence |
| 13 | V001, V002, V004, V007 | The `hash`, `pr` and `trees` scenes show sample IDs, "#42", check names and `c1` when the tag gives none. | none |
| 14 | V006 line 185 | An `[ON SCREEN]` state table described in words, with no paragraph after it, is not drawn. | none |

## 9. Verification at the end

- `make.sh qc V001-V009 V020 V022 V025` at 12:57: 12 PASS, 0 failed. For every video the script SHA-1 in the storyboard and in `VNNN.build.json` equals the script on disk, and the beat count equals the number of beat starts.
- Storyboards: no warning and no hint for any of the twelve. `python3 tools/check_course.py`: 0 problems. `python3 tools/inject.py --check`: 0 problems for each of the twelve scripts.
- Rebuilds ran one at a time from a detached queue started with `setopt NO_BG_NICE`, 12:15 to 12:56 (the automatic final pass had finished at 12:09). One `--look` render (prefix `b1f-`); the look folder, all frames and the scratch sandbox are deleted. Logs: `video/production/.cache/inspect-b1f/rebuild.log`; working notes: `video/production/.cache/inspect-b1f-progress.md`.
- **Disk**: 3.4 GB free at 12:02 and 4.2 GB when the first build started; it fell to 2.7 GB during that build's render (12:17) and stood at 17 GB when the build ended, 25 GB at the end: space was freed by someone else in between. The queue checks the free space before every build and stops below 3 GB; it never had to.
- No `git` command was run in the course directory, nothing was run against GitHub, no video outside these twelve was touched, and nothing in `tools/` was edited.

## 10. Ready to upload?

V001 to V009, V020, V022 and V025 are ready from the tool's and the eyes' side: QC PASS for all twelve, frames inspected, every fix re-inspected in the new MP4, no answer on screen before or during its question. One visible mistake remains and cannot be closed from the script: the GitHub note of V025 (4:50) is cut in the middle of its sentence by the library; the narration now says the sentence in full, and nothing shown is wrong. Before upload, a person should do the "ears" items, at least the V005 clip at 2:06 and the places listed in section 7. Nine of the twelve files are newer than any copy uploaded before today (V002 to V008, V020, V025), so batch 1 must be uploaded again from these files.
