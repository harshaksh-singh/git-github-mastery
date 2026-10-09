# Library fix round 2: report

9 October 2026. One round of fixes in the pipeline library for the defects the frame inspectors of the six batches could not close from the scripts, then a rebuild of the videos whose pictures change. Working notes: `video/production/.cache/libfix2-progress.md`.

## 1. Summary

- Changed files: `tools/video_storyboard.py`, `tools/video_animate.py`, `tools/video_animtest.py` (self-tests only). No JavaScript in `tools/anim/`, nothing in `tools/video_build.py`, no script, no narration.
- Fixed: items 1 to 5 of the brief. Not changed: item 6 (sample values; the frozen v1 library forbids it, the tags are listed in section 5) and item 7 (smaller layout items, section 6).
- Affected videos (storyboard, slide or clip changes): **112 of 201**. Unaffected: 89, all of which reproduce their storyboard on disk byte for byte, their slide hashes and their clip ids.
- Spoken text: identical for all 201 videos (the text given to the voice, beat by beat, old code against new code). Every rebuild reused its verified voice clips.
- Rebuilt: **112 of 112**, every one at the first attempt; QC PASS: 112; not PASS: none. Frames of the changed places of all 112 were looked at: every defect is gone and nothing beside it broke.
- **To upload again:** V003 V005 V008 V009 V010 V017 V018 V019 V020 V021 V024 V025 V029 V032 V033 V034 V035 V037 V038 V040 V042 V043 V044 V047 V050 V052 V054 V055 V056 V057 V058 V059 V060 V061 V062 V064 V066 V078 V080 V081 V083 V084 V091 V093 V094 V096 V098 V106 V109 V114 V117 V121 V122 V123 V125 V128 V129 V134 V135 V136 V137 V138 V140 V141 V142 V143 V144 V145 V146 V147 V148 V149 V150 V151 V152 V153 V154 V156 V157 V158 V159 V160 V161 V162 V163 V164 V165 V166 V167 V168 V169 V171 V172 V173 V174 V175 V176 V177 V178 V179 V180 V182 V183 V184 V185 V189 V192 V193 V195 V196 V197 V199

## 2. The fixes

### Fix 1: directions that quote text (`video_storyboard.py`)
- `quoted_section_line()`: a direction of the form `<words naming a section>: "quotation"` (also two quotations) is drawn as the quotation with its source as the label; the section's table, box or list is no longer looked up for it. A direction that names a table, row, box or drawing keeps the lookup.
- "Questions 1 and 2 of section N.M" (unquoted) shows those items of the section's list, not the whole list (V145).
- `prose_callout()`: `Callout:` / `Lower third:` + a short label + sentences that contain quotation marks is drawn as label and the whole text. Before, everything up to the first quotation mark became the label and the text after the last one was dropped (V020, V025, V138 11:18, V159, V164, V096).
- `quote_callout()`: words after the quotation that only describe the layout (`"Unverified", as a callout.`) are not printed (V018). A description of more than 12 words that happens to quote a word and goes on after it is no longer a callout: a `[TERMINAL]` direction falls to its `labs/run` card (V059, V060, V162, V195), an `[ON SCREEN]` one to the key points of its narration (V125, V145 8:59, V185).
- A bare `[ON SCREEN] Unverified.` / `Outdated advice.` / `Version note.` / `Assembled, not authoritative.` puts that word as a badge on the key points read under it (V167, V168, V171, V173, V176, V177, V189, V199). Before it drew nothing.
- Videos: V018 V020 V025 V059 V060 V096 V125 V138 V143 V144 V145 V149 V152 V159 V162 V163 V164 V167 V168 V171 V173 V176 V177 V185 V189 V195 V199

### Fix 2: the big number on a key point (`find_count` in `video_animate.py`)
- No number from a piece of a larger number, a decimal, a version or a section number ("24 NEW SECRETS" from 28,649,024; "17 FOLLOWS" from section 20A.17; "6 SYMPTOMS" from twenty-six).
- No number after a numbered name (Gate 3, Workflow 7, Level 8, Incident 7), none inside a quoted title ("Your turn. Do Lab 7.1, "A bare server and two clones" ..."), none when the words after it are not the things counted ("12 AS", "2 OF ITS", "3 FOR ITS", "85 FOR THIS").
- The unit is the thing counted: "3 COMMITS" (was "COMMITS AS"), "40 ENGINEERS" (was "ENGINEERS RUNS"), "2 THINGS" (was "THINGS THIS").
- Checked against all 755 key points where the old rule fired: 85 change (listed while developing; five gain a correct count, e.g. "9 SYMPTOMS" in V147).
- Videos: V005 V009 V010 V017 V029 V032 V037 V038 V040 V052 V066 V080 V081 V083 V084 V094 V109 V114 V121 V122 V123 V125 V128 V129 V134 V135 V138 V140 V141 V142 V144 V147 V148 V149 V150 V151 V153 V154 V157 V158 V160 V164 V169 V171 V172 V173 V174 V177 V179 V180 V182 V184

### Fix 3: tables (`video_storyboard.py`)
- `text_table()`: a complete line under a complete line is a new row. A line continues the row above only when its first cell is empty, is indented more than the first row's, when the first cell above ends openly (comma, "and", an unclosed quotation), or when the line leaves a column empty and continues a cell that ends openly. Step numbers centred under their column head are rows (V042 timeline: 1 row became 6). Fixed tables: V042, V055, V057, V062, V064, V078, V093, V098, V143, V169 (V008's ladder is parsed correctly too; it is replaced by a scene).
- A drawing of numbered step columns ("1 CONTAIN  2 ASSESS ...") becomes one row per step with that column's items (V192).
- `whole_words()`: after the layout is chosen, a column narrower than its longest plain word (measured with the advance widths of Helvetica Neue, the slide's font) takes the missing width from columns that have room. Measured in Chrome over all 586 table slides: 9 tables broke a word before ("unchange/d" V019 V033 V083 V091 V167, "COMMITTE/R" V020, "COUN/T" V196, "recommende/d" V117, V192), none does now, and no other table changed.
- `inline_html()` / `_strip_marks()`: an escaped asterisk or underscore is a literal character, not emphasis (V044 refspec table).
- Videos: V019 V020 V033 V042 V044 V055 V057 V062 V064 V078 V083 V091 V093 V098 V117 V143 V167 V169 V192 V196

### Fix 4: title of a card of commands (`video_storyboard.py`)
- `command_title()`: when a `[TERMINAL]` direction named a lab, a card of commands is titled with the lab it runs in: the lab the card itself starts (`labs/run X`), else the lab of the transcript that follows, else the lab of the transcript before. A card whose section named no lab keeps "lab sandbox".
- A path such as `labs/verify-all.sh` in a direction is not a lab and never a title (V106).
- Videos: V034 V037 V050 V058 V094 V106 V136 V137 V138 V140 V143 V145 V146 V161 V165 V168

### Fix 5: how long a badge and a headline live (`build()` in `video_storyboard.py`)
- A badge ("GITHUB") belongs to the paragraphs read directly under its direction: it ends at the next picture, list, direction, or at the next bold lead-in once a paragraph has been read under it.
- A headline (bold lead-in) that a terminal has interrupted is not carried into the key points that follow a later direction (the GitHub walkthroughs of V134, V140; "Step N" over later paragraphs).
- Deliberately narrow: a headline is kept over the paragraphs of its topic, also across a table, a scene or a callout. A wider rule (any picture ends the headline) was tried and withdrawn: it changed 81 videos, mostly where the headline still fitted.
- Videos: V003 V008 V021 V024 V035 V037 V043 V044 V047 V054 V056 V057 V059 V061 V066 V134 V135 V140 V143 V144 V146 V148 V150 V151 V153 V154 V156 V157 V158 V159 V160 V162 V165 V166 V168 V172 V173 V174 V175 V177 V178 V180 V183 V193 V195 V197

## 3. Tests and proof

- Self-tests: a new section `fixes2_planner()` in `tools/video_animtest.py` (17 checks for this round: directions, counts, the three kinds of text table, escaped asterisk, column widths, and a storyboard of a test script for quoted hook, label badge, full note, card title, headline and badge lifetime). `python3 tools/video_animtest.py --fixes` runs these and the earlier planner checks without rendering: 36 PASS, 0 FAIL. The same section runs inside the full self-test (section b).
- `python3 tools/video_build.py --speech-selftest`: all correct (the voice step was not touched).
- Frozen v1: `python3 tools/video_animtest.py --compat` (planner comparison, no rendering) gives the same result after the round as before it: 320 tags identical, 3,731 drawings identical, scene slides and animation plans of the 12 unedited scripts identical; the one FAIL is the old one ("batch one scripts were edited since the freeze"). No JavaScript changed, so the picture comparison (`--compat pictures`) has nothing new to compare and was not run.
- Diff over all 201 scripts (old tools against installed tools, in a scratch directory): storyboards beat by beat, the HTML hash of every slide, the id of every animation clip (an id is the hash of the clip's page), and the text given to the voice. Result: 112 affected, 89 unaffected, spoken text equal everywhere, no storyboard warning or hint anywhere.
- Unaffected videos: for all 89 (not only a sample of 30) the storyboard regenerated by the installed code equals `storyboards/VNNN.json` byte for byte, every slide hash equals `slides/VNNN/manifest.json` and every clip id equals `anim/VNNN/anim.json`. A sample of 30: V001 V006 V012 V015 V023 V028 V036 V045 V049 V063 V068 V071 V074 V077 V085 V088 V092 V099 V102 V105 V110 V113 V118 V124 V130 V133 V170 V187 V191 V200.
- Look renders before and after (prefix `libfix2-`, one Chrome at a time, looked at): V149 hook, V025 note, V009 and V123 key points, V167 and V057 and V192 and V044 tables, V034 and V037 cards, V134 and V140 walkthrough key points, V167 badge. Folders deleted at the end.
- Installed atomically (new file, compile, self-tests, rename) for the three files together.

## 4. Rebuilt videos

Each: `storyboard`, `slides`, `animate` and `qc` under `nice -n 20`, `voice` at normal priority, one video at a time from a detached queue (`setopt NO_BG_NICE`), free space checked before each (15 to 23 GB throughout; stop set at 6 GB). The queue ran from 15:28 to 23:36; from about 21:20 the machine was under heavy load from other work (load average 44 to 87) and single builds took up to an hour, without any failure or retry. No storyboard had a warning or hint. Frames: the last moment of up to six changed beats per video, taken from the new MP4 and looked at.

| Video | Fixes | Changed beats | QC | Length | Seen in the frames |
|---|---|---|---|---|---|
| V003 | 5 | 2 | PASS | 15:52 | 10:29 "Now the prediction ..." key point no longer carries "Step 5: a second commit"; frame clean |
| V005 | 2 | 1 | PASS | 15:13 | 13:06 "Your turn. Lab 35.1 ..." no "3 REPOSITORIES" number; plain key point |
| V008 | 5 | 2 | PASS | 16:17 | 11:51 "The last step fills the working tree" without the stale "Step 5" headline; glyph and text clean |
| V009 | 2 | 2 | PASS | 16:00 | 14:00 "Your turn ... two branches and a tag" no "2 BRANCHES"; book drawing |
| V010 | 2 | 2 | PASS | 15:31 | 13:31 "Your turn ... three object types" no big number |
| V017 | 2 | 2 | PASS | 16:46 | 14:41 "Your turn. Do Lab 2.4" no "3 WAYS" |
| V018 | 1 | 2 | PASS | 18:25 | 5:21 callout shows "Unverified" alone; ", as a callout." is gone; caption bar intact |
| V019 | 3 | 1 | PASS | 15:32 | 4:58 state table: "unchanged" whole in the Remote and GitHub columns (was "unchange/d") |
| V020 | 1,3 | 6 | PASS | 16:30 | 2:43, 3:10, 3:25 column head "COMMITTER" on one line; 5:22 GitHub note shown in full (label GitHub, all sentences) |
| V021 | 5 | 3 | PASS | 16:35 | 6:01 and 7:36 key points keep their own headlines, the leftover GITHUB badge is gone |
| V024 | 5 | 2 | PASS | 13:47 | 5:25 key point under its own headline "When to use it, and when not"; no leftover badge |
| V025 | 1 | 1 | PASS | 15:09 | 5:00 GitHub note complete ("... where "created from" is recorded. And GitHub computes ... too."), label GitHub |
| V029 | 2 | 2 | PASS | 12:56 | 3:20 "The pass rule" key point without the false number "85 FOR THIS" |
| V032 | 2 | 2 | PASS | 15:40 | 13:41 "Your turn ... which of three changes conflicts?" no "3 CHANGES CONFLICTS" |
| V033 | 3 | 2 | PASS | 18:20 | 5:37 state table: "unchanged" whole in HEAD, Remote and GitHub columns |
| V034 | 4 | 2 | PASS | 19:50 | 10:13 card "git restore --ours config/eval.yaml" titled labs/run ch08/restore-sides (was pre-merge-checks) |
| V035 | 5 | 1 | PASS | 17:44 | 10:43 "The fix is to abort ..." no stale "Renames" headline |
| V037 | 2,4,5 | 4 | PASS | 18:52 | 0:47 "None of the three needs a bug in Git." without "3 NEEDS"; 7:16 no stale "Part 1" headline; 8:48 card titled labs/run ch08/audit-merge |
| V038 | 2 | 1 | PASS | 19:07 | 16:35 "Your turn. Do Lab 7.1 ..." no "2 CLONES" |
| V040 | 2 | 1 | PASS | 17:39 | 15:18 "Your turn. Do Lab 7.3 ..." no "3 CONFIGURATIONS" |
| V042 | 3 | 1 | PASS | 17:00 | 6:29 lease timeline is six rows (steps 1 to 6) with every cell in its own row (was one merged row) |
| V043 | 5 | 1 | PASS | 17:18 | 6:32 GITHUB badge on the fork paragraph only, without the terminal step's headline |
| V044 | 3,5 | 7 | PASS | 17:31 | 3:15 refspec table shows +refs/heads/*:refs/remotes/origin/* with asterisks, upright, no backslash; 8:29 GITHUB badge on the refs/pull paragraph; 8:53, 10:22, 11:54 Parts 6 to 8 without the badge |
| V047 | 5 | 1 | PASS | 19:33 | 12:29 "Kind four, untracked files ..." without the stale "Why --hard" headline |
| V050 | 4 | 2 | PASS | 16:23 | 7:25 card "git stash push -m ..." titled labs/run ch11/stash-basics (was ch11/clean) |
| V052 | 2 | 2 | PASS | 15:23 | 0:31 quoted hook sentence as a plain key point, no "3 COMMITS" number |
| V054 | 5 | 5 | PASS | 15:36 | 7:27 GITHUB badge on the squash-and-merge paragraph only; 8:31, 9:42, 10:19 later cases without the badge, own headlines |
| V055 | 3 | 2 | PASS | 15:47 | 2:52 todo table: pick and reword are separate rows (were merged), page 1/2 clean |
| V056 | 5 | 3 | PASS | 20:06 | 7:57 and 12:36 key points without the earlier part's headline |
| V057 | 3,5 | 2 | PASS | 17:22 | 3:13 exits table has five rows, one per command (was three merged); 11:09 "Second case." without the old part headline |
| V058 | 4 | 2 | PASS | 13:56 | 6:37 card "git range-diff main ORIG_HEAD HEAD" titled labs/run ch09/range-diff |
| V059 | 1,5 | 2 | PASS | 16:55 | 6:15 a card "labs/run ch09/shared-rebase" in place of the callout with the fragment "Add chunker"; 10:12 key point without stale headline |
| V060 | 1 | 1 | PASS | 16:18 | 5:28 card "labs/run ch09/force-push" in place of the callout with the fragment "Add chunker" |
| V061 | 5 | 1 | PASS | 16:27 | 8:22 "Note the line "Author: Asha Rao" ..." without the stale "Step 2" headline |
| V062 | 3 | 1 | PASS | 17:07 | 3:36 cherry-pick exits table has four rows (--skip and --abort were merged) |
| V064 | 3 | 1 | PASS | 16:47 | 3:18 range table: A^- and "--all, --branches, --tags, --remotes" are separate rows |
| V066 | 2,5 | 2 | PASS | 18:01 | 10:41 key point without stale headline; 15:34 "Your turn ... Four questions for the log" no "4 QUESTIONS" (the full stop after the long file name stands alone on a fourth line: the known code-chip wrap limit, batch 1-2 report #6) |
| V078 | 3 | 2 | PASS | 13:14 | 6:40 "Lost for good" table: each row whole (page 1/2), "objects were pruned" no longer a row of its own |
| V080 | 2 | 1 | PASS | 14:25 | 11:57 "Your turn. Do Lab 13.1, "Three kinds of tag"" no "3 KINDS" |
| V081 | 2 | 2 | PASS | 13:41 | 11:24 and 11:50 exercise cards without "2 CLONES" / "2 BUILDS" (11:50: lone full stop after the long file name, known limit) |
| V083 | 2,3 | 2 | PASS | 13:43 | 8:12 state table: "unchanged" whole in the Remote and GitHub columns; 11:56 no "2 FIXES" |
| V084 | 2 | 2 | PASS | 15:06 | 6:20 "Try it now ... three for its worktrees" without "3 FOR ITS"; 13:17 no "2 FIXES" (lone full stop after the file name, known limit) |
| V091 | 3 | 1 | PASS | 14:49 | 8:43 state table: "unchanged" whole in the HEAD and GitHub columns |
| V093 | 3 | 2 | PASS | 17:30 | 6:27 symptom table: one row per symptom on page 1/2, the quoted symptom no longer split |
| V094 | 2,4 | 2 | PASS | 14:59 | 10:10 the card of four git config commands is titled labs/run ch23/subtree, the lab of the last transcript (before: lab-15-2-subtree; the block itself belongs to no lab, so either title is only the nearest lab); 12:48 no "2 SUBTREE OPERATIONS" (lone full stop, known limit) |
| V096 | 1 | 1 | PASS | 16:35 | 11:00 GitHub Actions note shown in full with its label (was a label run together with a half quotation) |
| V098 | 3 | 1 | PASS | 9:59 | 4:47 "Lost for good" table: eight whole rows, "objects were pruned; a stash entry likewise" joined to its row |
| V106 | 4 | 6 | PASS | 13:39 | 7:04, 7:30, 8:21, 9:28 command cards titled "lab sandbox"; labs/verify-all.sh is no longer a window title |
| V109 | 2 | 1 | PASS | 19:08 | 17:01 "Your turn. Do Lab 18.1 ..." no "3 WAYS" |
| V114 | 2 | 3 | PASS | 11:10 | 1:41 "Gate 5 comes after Module 18" without "5 COMES"; 9:35 no "4 EXERCISES" |
| V117 | 3 | 5 | PASS | 20:10 | 9:15, 9:52, 10:43 limits table: "recommended" whole in the Kind column on both pages, captions intact |
| V121 | 2 | 2 | PASS | 18:08 | 15:54 "Your turn. Do Lab 20.4 ..." no "2 IDENTITIES" |
| V122 | 2 | 1 | PASS | 16:38 | 14:59 "Your turn. Do Lab 20.3 ..." no "3 FAILURES" |
| V123 | 2 | 1 | PASS | 17:28 | 8:08 the count reads "3 / COMMITS" (was "3 / COMMITS AS") |
| V125 | 1,2 | 5 | PASS | 17:23 | 12:46 the walkthrough paragraph is a key point of its own sentence (was a callout made of a director's note and the fragment "changing the base branch of a pull request"); 13:09 command card unchanged in content; 17:08 no "5 COMMITS" |
| V128 | 2 | 4 | PASS | 16:28 | 14:42 and 16:14 exercise cards without "3 MERGE METHODS" / "3 BUTTONS" |
| V129 | 2 | 2 | PASS | 19:59 | 18:02 "Your turn. Do Exercise 22.4 ..." no "3 TEAMS" |
| V134 | 2,5 | 8 | PASS | 21:33 | 6:33 "Two details ..." without the stale "Changing rules" headline; 13:42 "The replay continues ..." without "Step 3"; 14:14 walkthrough key point with the GITHUB badge and no "Step 3"; 18:36 count reads "2 / THINGS" (was "THINGS THIS"); 19:06 no "3 BLOCKED MERGES" |
| V135 | 2,5 | 4 | PASS | 17:39 | 2:37 "Precisely" key point without the leftover badge; 10:47 "Step 3: where the two part ways" without "2 PART WAYS"; 15:39 no "8 PATHS" |
| V136 | 4 | 1 | PASS | 19:55 | 15:17 gh card titled labs/run ch18/lab-23-2-codeowners |
| V137 | 4 | 7 | PASS | 17:34 | 8:43, 9:23 cards titled labs/run ch14b/signing-backends; 10:12, 10:31 titled labs/run ch14b/ssh-signing (all four were ch06/signed-header) |
| V138 | 1,2,4 | 15 | PASS | 18:37 | 0:20 hook shows the quoted line "the last three commits are from the platform lead" with its source label (was the textbook's "GitHub, not Git" box); 9:17 to 11:01 cards titled with their own labs (spoof-author, signature-scope); 16:35 no "5 COMMITS" |
| V140 | 2,4,5 | 11 | PASS | 23:00 | 2:55 "Precisely" card without leftover badge; 8:21 "Every gh api call with GET is SAFE" without the stale "gh api" headline; 14:26 and 15:55 cards titled jq-rehearsal and lab-25-1-feature-cycle; 17:21 walkthrough key point with GITHUB badge and no "Step 6" headline; 20:29 no "5 SCRIPTS" |
| V141 | 2 | 2 | PASS | 10:27 | 8:43 "Your turn ..." no "4 EXERCISES" |
| V142 | 2 | 1 | PASS | 19:05 | 17:12 "The challenge is Exercise 26.3 ..." no "6 THINGS" |
| V143 | 1,3,4,5 | 7 | PASS | 21:05 | 0:22 and 0:42 hook shows question 3 itself with its source label (was the list of four questions); 12:33 event table: push and pull_request are separate rows; 13:57 try-it card without "Step 2" headline; 16:45 gh card titled labs/run ch20a/lab-26-5-path-filter |
| V144 | 1,2,5 | 4 | PASS | 14:49 | 0:30 hook shows question 4 itself; 2:35 key point without leftover badge; 12:51 no "2 SHELLS" |
| V145 | 1,4 | 9 | PASS | 18:34 | 0:09 and 0:36 hook shows questions 1 and 2 only (was all four of section 20A.1); 8:59 the second root cause is a key point of its own sentence (was a 100-word quotation that started mid-sentence); 13:10 to 14:25 cards titled labs/run ch20a/merge-ref (were shallow-checkout) |
| V146 | 4,5 | 4 | PASS | 20:15 | 13:35 key point without stale headline; 13:54 and 14:14 cards titled labs/run ch20a/lab-26-7-artifact |
| V147 | 2 | 5 | PASS | 20:56 | 9:29 "9 / SYMPTOMS" for "a table of nine symptoms" (a real count; before no number); 11:03, 16:00, 17:44 no numbers taken from section numbers ("17 FOLLOWS", "18 LABELS", "16 GIVES"); 18:44 no "6 THINGS" |
| V148 | 2,5 | 4 | PASS | 22:36 | 16:01 "Now predict for the tag push." without "Step 2"; 22:15 no "13 AND SECTIONS" (from 20A.13) |
| V149 | 1,2 | 4 | PASS | 23:06 | 0:23 and 0:44 hook shows the quoted question with its source label (was the textbook's "GitHub, not Git" box); 20:52 no "5 FLAWS" |
| V150 | 2,5 | 6 | PASS | 20:13 | 2:41, 3:03, 3:20 "Precisely," key points without the leftover GITHUB ACTIONS badge ("3 / RUNS" at 3:20 is a real count); 18:17 no "4 REUSABLE-WORKFLOW SURPRISES" |
| V151 | 2,5 | 10 | PASS | 15:27 | 2:26 "Workflow 6 builds ..." without "6 BUILDS", badge on its own paragraph; 3:56 and 4:23 without the leftover badge; 8:24, 8:36, 9:49 without the stale step headline |
| V152 | 1 | 2 | PASS | 21:50 | 0:34 hook shows the two quoted questions with their source label (was the textbook's "GitHub, not Git" box) |
| V153 | 2,5 | 3 | PASS | 17:59 | 11:56 key point without the stale case headline; 15:34 no "6 BROKEN WORKFLOWS" |
| V154 | 2,5 | 7 | PASS | 19:54 | 5:31, 7:15, 7:26, 8:25 key points with their own headlines and without the leftover badge ("2 / SWITCHES" is a real count); 17:16 no "6 BROKEN WORKFLOWS" |
| V156 | 5 | 4 | PASS | 19:43 | 3:47 and 5:24 key points with their own headlines, leftover badge gone |
| V157 | 2,5 | 3 | PASS | 20:29 | 3:22 "Precisely" card without leftover badge; 9:46 key point without stale headline; 18:04 no "5 PLANTED WEAKNESSES" |
| V158 | 2,5 | 5 | PASS | 16:35 | 2:52 to 5:29 key points with their own headlines, leftover GITHUB ACTIONS badge gone; 14:33 no "5 PLANTED WEAKNESSES" |
| V159 | 1,5 | 6 | PASS | 17:35 | 2:43 to 4:32 key points without the leftover badge; 5:56 the Unverified callout shows its whole text including the roadmap sentence |
| V160 | 2,5 | 3 | PASS | 23:20 | 0:55 "3 / STATEMENTS" for "None of the three statements is false" (a real count); 3:02 "Precisely" card without leftover badge; 3:45 "2 / FACTS" without the stale headline |
| V161 | 4 | 3 | PASS | 24:32 | 16:31 and 17:55 cards titled labs/run ch21a/lab-29-3-review (were workflow-audit) |
| V162 | 1,5 | 2 | PASS | 19:12 | 12:44 a card "labs/run ch21a/mutable-tag" in place of the callout made of the direction's own words; 14:40 key point without stale step headline |
| V163 | 1 | 4 | PASS | 20:33 | 0:11 and 0:39 hook shows question 3 itself with its source label (was the list of four questions) |
| V164 | 1,2 | 5 | PASS | 20:41 | 0:22 and 0:49 hook shows question 1 itself; 8:55 Root cause callout with its whole sentence pair (was cut inside the quotation marks); 18:38 no "6 LEAKED CREDENTIALS" |
| V165 | 4,5 | 3 | PASS | 23:46 | 3:11 key point with its own headline, leftover badge gone; 18:13 gh card titled labs/run ch21b/lab-30-2-dependabot |
| V166 | 5 | 1 | PASS | 21:50 | 16:35 "The replay continues with eradication ..." without the stale "Step 2: assess" headline |
| V167 | 1,3 | 5 | PASS | 22:50 | 6:12 UNVERIFIED badge on the paragraph that states the caveat; 7:50 OUTDATED ADVICE badge on its paragraph; 17:24 state table: "unchanged" whole in the Index column |
| V168 | 1,4,5 | 6 | PASS | 19:35 | 6:17 UNVERIFIED badge on the GitHub-side caveat; 11:12, 11:49, 12:01 key points without the stale "Step 3" headline; 13:54 card titled labs/ch21b/lab-31-1-tabletop.sh |
| V169 | 2,3 | 3 | PASS | 10:18 | 4:44 the two checklists are 11 rows, one item per row (were merged into three); 8:30 no "5 EXERCISES" |
| V171 | 1,2 | 3 | PASS | 19:50 | 7:57 OUTDATED ADVICE badge on the Git Flow note; 8:54 UNVERIFIED badge on the GitLab Flow caveat; 17:43 no "6 TEAMS" |
| V172 | 2,5 | 6 | PASS | 19:33 | 10:50, 11:02, 11:50 try-it and prediction cards without the stale step headline; 16:52 no "2 STRATEGIES" |
| V173 | 1,2,5 | 9 | PASS | 18:07 | 6:56 UNVERIFIED badge on the caveat; 7:20 the badge also stands on the quiz that follows in the same passage (no lead-in or picture between; the quiz is about that claim); 12:12 "40 / ENGINEERS" (was "ENGINEERS RUNS"), no stale headline; 13:29 no stale headline; 15:34 no "6 TEAMS" |
| V174 | 2,5 | 2 | PASS | 18:36 | 14:06 key point without the stale "Step 8" headline; 16:32 no "4 PULL REQUESTS" |
| V175 | 5 | 1 | PASS | 20:02 | 13:52 key point without the stale "Step 8" headline |
| V176 | 1 | 4 | PASS | 20:58 | 3:43 UNVERIFIED badge on the Hugging Face caveat; 6:21 and 6:51 badge on the four-caveats passage ("4 / CAVEATS" is a real count; the hash drawing at 6:51 carries the library's decorative "2e76f67", known from batch 5A #5, not touched) |
| V177 | 1,2,5 | 3 | PASS | 20:13 | 3:06 badge ASSEMBLED, NOT AUTHORITATIVE on its paragraph; 13:15 key point without the stale "Step 7" headline; 18:12 no "8 PATHS" |
| V178 | 5 | 4 | PASS | 22:54 | 17:09 "4 / THINGS" without the stale "Step 4" headline; 17:23 no stale headline |
| V179 | 2 | 2 | PASS | 13:05 | 0:44 "Level 8 ends by asking ..." without "8 ENDS"; 12:49 "4 / PAGES" (was "PAGES PLUS") |
| V180 | 2,5 | 3 | PASS | 19:01 | 12:58 "Preview the push, then push." without the stale headline; 16:43 no "3 REPOSITORIES" |
| V182 | 2 | 3 | PASS | 17:22 | 15:03 and 15:35 exercise cards without "5 OPERATIONS" |
| V183 | 5 | 1 | PASS | 17:13 | 12:02 walkthrough key point without the stale "The preservation" headline |
| V184 | 2 | 1 | PASS | 17:49 | 6:50 "5 / GROUPS" for "Twenty-six symptoms in five groups" (was the false "6 / SYMPTOMS" cut out of twenty-six) |
| V185 | 1 | 1 | PASS | 15:06 | 7:28 key point "How to run one" in place of the callout made of the direction's words and three quoted reports |
| V189 | 1 | 1 | PASS | 21:00 | 8:02 UNVERIFIED badge on the caveat paragraph, without the headline of the passage before the terminal |
| V192 | 3 | 1 | PASS | 19:56 | 8:35 the six-step drawing is six rows, one per step, each with its own items (was two rows that joined separate lines); the slide renderer shrank the type slightly to fit the frame |
| V193 | 5 | 2 | PASS | 16:19 | 11:00 key point without the stale "The detection" headline |
| V195 | 1,5 | 2 | PASS | 16:06 | 8:18 a card "labs/run ch29/case-wrong-upstream" in place of the callout made of the direction's words and "Already up to date"; 11:11 question card without the stale "Part 5" headline |
| V196 | 3 | 3 | PASS | 12:49 | 2:02 and 2:08 column head "COUNT" on one line on both pages (was "COUN/T") |
| V197 | 5 | 1 | PASS | 17:53 | 12:51 key point without the stale "How to run it" headline |
| V199 | 1 | 1 | PASS | 22:05 | 4:19 UNVERIFIED badge on "Every date in the last three rows of the table." ("3 / ROWS" is a real count) |

**Verification at the end (9 Oct, 23:40 to 23:55):** `make.sh qc` over all 112 again: 112 checked, 0 failed. For each of the 112 the script SHA-1 in the storyboard and in `VNNN.build.json` equals the script on disk, the beat counts agree, the storyboard has no warning or hint, and the MP4 is from this round. `python3 tools/check_course.py`: 0 problems (no script was edited, so `inject.py --check` had nothing to check). `video_animtest.py --fixes`: 36 PASS; `--compat`: 3 PASS and the one old FAIL, as before the round. No `git` command was run in the course directory, nothing was run against GitHub, no rendering mode of `video_animtest.py` was used, `make.sh selftest` was not run. Frame sheets, look folders and the scratch copies are deleted; the queue log, the list of changed beats (`places.json`) and the inspection notes stay in `video/production/.cache/libfix2/`.

Not listened to: the sound was not changed (same voice clips; QC C and E checks pass), so nobody listened again.

## 5. Item 6, not changed: scenes that show library sample values

The `hash`, `pr`, `trees` and `remotes` scenes belong to the frozen v1 library. Their defaults cannot change without changing approved pictures of frozen tags (34 of the 49 tags below are in the frozen set, and the JavaScript default is the same code for the others). The library already takes explicit values: `number=off` or `number=N` for `pr`, `commits=` for `trees`, `ids=` for `remotes` and `hash`. These tags give none; a script editor can add the value (only the `[ANIMATION]` line changes):

| Video | Line | Frozen | What is shown | Tag |
|---|---|---|---|---|
| V001 | 62 | frozen | shows sample object IDs (give ids=) | hash: differs=date steps=one,different,same |
| V001 | 76 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: setup, edit, add, commit, reset file=notes.txt |
| V002 | 56 | frozen | shows commits A, B, C ... (give ids=) | remotes: with Asha |
| V002 | 112 | frozen | shows "Pull request #42" (give number=off or number=N) | pr: feature into main cmd=off layers=on title=A_pull_request_is_a_GitHub_object |
| V002 | 274 | frozen | shows "Pull request #42" (give number=off or number=N) | pr: feature into main blocked cmd=off layers=on steps=branch,push,merge,review,checks title=The_merge_is_block |
| V004 | 28 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: setup, edit, add, commit file=README.md names=Working_tree,Index,Repository |
| V005 | 28 | frozen | shows commits A, B, C ... (give ids=) | remotes: solo fetch note=a_bare_repository_on_disk title=One_clone,_one_server |
| V005 | 91 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: setup, edit file=eval/runner.py |
| V006 | 47 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: setup, edit, add, commit file=eval/runner.py |
| V007 | 65 | frozen | shows sample object IDs (give ids=) | hash: differs=byte |
| V007 | 93 | frozen | shows sample object IDs (give ids=) | hash: differs=parcel |
| V010 | 43 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=rules.txt order=reverse subs=files_on_disk,the_next_commit,the_last_commit |
| V010 | 77 | frozen | shows commits A, B, C ... (give ids=) | remotes: solo fetch title=What_travels:_objects_and_refs |
| V010 | 432 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: setup, edit, add, commit file=rules.txt order=reverse subs=files_on_disk,the_next_commit,the_last_commi |
| V011 | 26 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=src/retriever.py order=reverse names=Working_tree,Index,HEAD_commit steps=setup,edit,add,restore t |
| V011 | 500 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=src/retriever.py order=reverse names=Working_tree,Index,HEAD_commit steps=setup,edit,add cmd=off t |
| V012 | 71 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: setup, edit file=.env |
| V013 | 28 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=config/settings.yaml steps=setup,edit,add,restore title=Three_places_for_every_file |
| V013 | 65 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=config/settings.yaml steps=setup,edit,add,restore title=Where_from,_and_where_to |
| V013 | 425 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=config/settings.yaml steps=setup,edit,add,restore title=Restore,_in_one_picture |
| V014 | 83 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=src/app.py steps=setup title=What_Git_holds_a_copy_of |
| V015 | 26 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=config/settings.yaml steps=setup,edit,add,commit title=Three_places,_one_in_the_middle |
| V015 | 380 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=config/settings.yaml steps=setup,edit,add,commit title=The_index,_in_one_picture |
| V016 | 24 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=src/retriever.py steps=setup,edit,add,commit title=Three_places,_three_comparisons |
| V016 | 693 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=src/retriever.py steps=setup,edit,add,commit title=Three_places,_three_diffs |
| V017 | 24 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=src/retriever.py steps=setup,edit,add,commit title=Stage,_then_commit |
| V017 | 603 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=src/retriever.py steps=setup,edit,add,commit title=What_a_plain_commit_records |
| V018 | 50 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=config/settings.yaml steps=setup,edit title=A_promise,_not_a_blindfold |
| V022 | 71 | frozen | shows commits A, B, C ... (give ids=) | remotes: steps=setup,teammate-push |
| V023 | 73 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=configs/eval.yaml steps=setup,edit |
| V025 | 79 | frozen | shows commits A, B, C ... (give ids=) | remotes: with Asha steps=setup,teammate-push,fetch |
| V029 | 67 | frozen | shows sample object IDs (give ids=) | hash: differs=date |
| V031 | 75 | frozen | shows sample object IDs (give ids=) | hash: differs=byte |
| V033 | 43 | frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=config/eval.yaml steps=setup names=Working_tree,Index,HEAD subs=the_file_with_marker_blocks,three_ |
| V047 | 58 | not frozen | shows commit labels "c1"/"c2" (give commits=) | trees: state=2,2,2 history=off steps=setup,reset-soft,reset-mixed,reset-hard id=steps title=What_a_reset_write |
| V047 | 104 | not frozen | shows commit labels "c1"/"c2" (give commits=) | trees: names=The_desk,The_draft_page,The_bookmark subs=working_tree,index,the_branch versions=the_entry_before |
| V050 | 46 | not frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=debug_dump.json in=wt absent=no_object versions=its_content history=off steps=setup title=An_untra |
| V066 | 624 | not frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=docs/metrics.md versions=as_committed,with_a_leftover_marker state=2,2,1 steps=setup history=off t |
| V077 | 40 | not frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=train.yaml steps=setup,edit,add,reset history=off versions=epochs:_3,epochs:_5 title=What_git_add_ |
| V078 | 75 | not frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=any_file at_reset_mixed=60 state=3,2,1 steps=setup,reset-mixed history=off versions=committed,stag |
| V087 | 69 | not frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=sample.csv steps=setup,add,commit names=Working_tree,Index,Repository subs=w/_on_disk,i/_staged,wh |
| V087 | 143 | not frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=loader.py steps=setup,add,commit,restore names=Working_tree,Index,Repository subs=w/_on_disk,i/_st |
| V088 | 60 | not frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=eda.ipynb steps=setup,add,commit names=Working_tree,Index,Repository subs=the_file_you_run,what_gi |
| V088 | 72 | not frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=eda.ipynb steps=setup,add,commit names=Working_tree,Index,Repository subs=she_ran_the_notebook,wha |
| V089 | 77 | not frozen | shows commit labels "c1"/"c2" (give commits=) | trees: state=3,2,1 versions=last_commit,staged,on_disk steps=setup,commit history=off title=Rule_one:_a_commit |
| V106 | 24 | not frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=config.toml steps=setup,edit,add say_setup=The_index:_the_proposed_next_commit say_edit=Work_in_pr |
| V106 | 90 | not frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=config.toml steps=setup chips=in_conflict,stages_1_2_3,ours say_setup=During_a_conflict,_one_path_ |
| V153 | 354 | not frozen | shows commit labels "c1"/"c2" (give commits=) | trees: id=eol file=scripts/deploy.sh versions=CRLF,LF say_setup=The_commit,_the_index_and_the_working_tree_all |
| V160 | 354 | not frozen | shows commit labels "c1"/"c2" (give commits=) | trees: file=.github/workflows/12-secure.yml versions=intact_workflow_12,the_cleanup steps=setup,edit,restore h |

## 6. Not fixed, and why

- **Item 7** (paged textbook table one page behind in V166; `replay:` ending before its last step; a mark pushing a branch chip onto an edge; the "bypass" mark touching a zone label; the `objects` pill over a row): not attempted. Four of the five are in the scene JavaScript; any change there gives every clip of every video a new id, so all 201 videos would have to be rendered again, and the frozen-picture comparison would have to be run in full. That is out of proportion for layout items.
- **V060's early answer**, and anything that needs a script to be restructured: excluded by the brief.
- **Headlines that outlive their topic without a terminal in between** (a quiz under the last lead-in after a table or a scene): left; the rule cannot tell these from paragraphs that continue the topic. A bold lead-in in the script fixes each.
- **A direction that names a table outside the textbook** (V029 `The table "The four parts" from the assessment guide`, V045, V196): still drawn as its own words.
- **A full stop alone on the last line after a long file name** in a key point (seen in V066, V081, V084, V094 exercise cards): the known code-chip wrap limit (batch 1-2 report, item 6); these cards showed a number layout before.
- **V094 10:10**: the card of four `git config` commands is titled with the nearest lab (`labs/run ch23/subtree`); the block belongs to no lab.
