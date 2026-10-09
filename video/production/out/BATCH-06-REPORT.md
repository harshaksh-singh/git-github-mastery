# Batch 6 (V179 to V201): finishing report

Written 2026-10-09 by the finishing inspector of V179 to V201 (design-review briefing; the diagnosis method, worked cases and incident drills; incident summaries, gate briefing, interview series, final test and capstone; Git's future and the course farewell). Voice: the macOS voice Tara at 165 words per minute. Every video carries the animation layer and was voiced with the repaired voice step. The form follows `BATCH-05B-REPORT.md`.

## 1. Result

- **23 of 23 videos built, 23 of 23 PASS from the QC tool** (`make.sh qc V179-V201`, run at about 09:13 after the last build): 1920x1080, 30/1 fps, H.264 and AAC, picture and sound equal within 0.015 s, built from the script as it is now, storyboards with no warning and no hint. Warnings: subtitle line length (E5, all 23) and reading speed (E6, 22 of 23); two pace warnings (C1/C2, three identical takes) in V187 and V192 (section 7).
- Total length 6 h 40 min, 1.77 GB. Files: `video/production/out/VNNN.mp4` with `.srt`, `.chapters.txt`, `.build.json`; QC reports in `video/production/out/qc/`.
- **At the start** (07:5x): V179 to V195 were built and passed QC; V196 to V201 were still being voiced by the main run (`out/voice.log`). All six came out of the main run OK (V196 08:01, V197 08:10, V198 08:22, V199 08:37, V200 08:52, V201 09:05); none failed, so none had to be rebuilt for a failure.
- **13 videos were rebuilt in full** with script fixes (storyboard, slides, animate under `nice -n 20`; voice at normal priority; QC niced; one at a time from a detached queue started from a shell with `setopt NO_BG_NICE`), 08:13 to 09:12: V179, V181, V182, V183, V184, V185, V186, V190, V192, V193, V196, V199, V200. Each was built once. **Every voice build succeeded at the first attempt; no sentence was refused.** Free disk stayed at 11 to 13 GB.
- **Not rebuilt:** V180, V187, V188, V189, V191, V194, V195, V197, V198, V201 (nothing needed changing).
- **How they were inspected.** From frames of the finished MP4s with the script, the storyboard and the `.srt` open: the last moment of every explainer-scene beat, the middle of each long scene, every ASCII drawing, every silent hold and prediction pause, and six frames spread over the length: 25 to 43 frames per video, about 700 in all, looked at as contact sheets of six half-size frames, with strips and crops where a sheet left a doubt (about 25). Storyboard scans by script for: silent holds on non-terminal slides, callouts under unrelated narration, late steps, inherited key-point headlines, caveat words on screen and in nearby narration; and a scan of the text given to the voice (`.cache/tts/VNNN.spoken.txt`) for director notes read aloud. **Drills first:** in every incident video the pre-demo DIAGRAM section and everything before the script's reveal were checked for the cause (section 3). After each rebuild the changed places were looked at again in the new MP4 (2 to 6 frames each, about 45 in all); the unchanged parts of a rebuilt video were not looked at a second time. New or changed scene tags were checked with `--look` first (prefix `b6-`, one at a time, 2 renders).
- **Not done: nobody listened.** No audio was heard at any point. Section 7 lists what was done for the sound.

"Explainer scenes" is the share of the running time during which a library scene or an animated commit graph is on screen. "QC tool" is the result of `make.sh qc VNNN`. "Silent page" means a page of a paged table that stood on screen with no sentence.

## 2. Per video

| Video | Length | Size | Explainer scenes | QC tool | What was fixed | Still imperfect |
|---|---|---|---|---|---|---|
| **V179** Design-review briefing | 13:05 | 57 MB | 27 % | PASS | The "Objections from five directions" cards stood 17.5 s in silence (3:42) because an `[ANIMATION] end` stood between the tag and its paragraph: the stray `end` removed, the cards now build under "The defence ..." (3:42 to 4:00). | The first 5 s of that paragraph show the empty card scene (cards are timed to their mentions). |
| **V180** Diagnosis method, worked case 1 | 19:01 | 88 MB | 20 % | PASS | Nothing changed (not rebuilt). H4 checked: the "What we know so far" box shows only the observed behaviour (6:50); the hypothesis cards are unmarked until after the test (11:05, marks 11:40); the root-cause box comes after the test (11:51). Fix-list: no director note is spoken any more. | Inherited key-point headlines "Execute, one change at a time" over the push quiz (12:44) and "Prevent" over the try-it (14:01). |
| **V181** Worked case 2, the toolbox | 17:08 | 79 MB | 22 % | PASS | Toolbox table page 1 stood 3 s silent (4:15): paragraph split, no word changed (4:15, 4:23). | Inherited headline "Evidence" on a blank key point (7:20). |
| **V182** Operations in progress | 17:22 | 73 MB | 25 % | PASS | Section 29.6 table: four pages, 12 s, stood silent (7:07 to 7:19), then the director note "Point at the HEAD column when the table is complete" was read aloud. Now one sentence per operation made of the table's own cells (state file and HEAD), and "So look at the HEAD column: ..." (7:07 to 7:33). Fix-list (`ORIG_HEAD`): line 185 now says a capital name was "left by a command: by an operation still in progress, or by one that has finished", and the listing step names `ORIG_HEAD` as a record of a past command: closed by the scene pass, checked. | None seen. |
| **V183** Preserving evidence, GitHub-side evidence | 17:13 | 77 MB | 23 % | PASS | Five-sources table page 1 stood 3 s silent (4:45): paragraph split, no word changed (4:45, 4:52). Caveats ("None of the commands was executed here", "Not stated in the page") read. | None seen. |
| **V184** Lowest-risk fix, symptom catalog | 17:49 | 84 MB | 27 % | PASS | Table "How the method itself fails" stood 6.8 s in silence (8:19): one sentence made of its first column (8:20). Fix-list: the catalog groups "submodules, LFS and scale" are now defined in the narration (submodule, Git LFS): closed, checked. | The `walk` column head written `stop,_and` renders as two heads "stop" and "and" (7:27). |
| **V185** The incident loop, severity | 15:06 | 65 MB | 25 % | PASS | (1) The try-it "Cover the table and write the seven stages" was paused over page 2 of the loop table (its answer, 2:42 to 2:52), page 1 read in the same breath: paragraph split, and a `cards` card "Cover the table" (look `b6-v185cover`) carries the try-it (2:42 to 2:53). (2) The prediction "Does the server keep a reflog?" was asked over page 2 of the evidence table ("current value only"), page 1 silent (3:15): prediction and pause moved before the table (3:15 to 3:27), and one sentence per page made of the table's cells (3:27, 3:34). (3) Director notes "Point at ... Point at ... trace the long arrow" read aloud: "Look at ... Look at ... follow the long arrow" (7:09). | None seen. |
| **V186** Drills: hard reset, disappeared branch | 17:34 | 79 MB | 23 % | PASS | The reflog timeline (`walk` t1) ended at row 6: the rows "also lost: a staged file / an unstaged edit" were never shown (8:20). One sentence from those cells added; all eight rows are on screen by 8:34. H4 checked (section 3). | None seen. |
| **V187** Drills: local-only commit, misunderstood conflict | 17:38 | 78 MB | 22 % | PASS; warn C1/C2 | Nothing changed (not rebuilt). H4 checked. | Inherited headline "The recovery is additive" over the Incident 9 opener (4:11). In the merge graph the notes "Asha: cap" and "Asha: halve the rate" are crossed by edges (11:02 to 11:50; library #3). Pace warning: section 7. |
| **V188** Rebased shared branch, senior standard 1 | 18:24 | 84 MB | 20 % | PASS | Nothing changed (not rebuilt). H4 checked. Fix-list (legibility, 13 commits): IDs readable at 720p (10:47). | One edge passes just under an ID label in the 13-commit graph (10:47). |
| **V189** Drills: force push to the wrong branch, rewritten production | 21:00 | 91 MB | 24 % | PASS | Nothing changed (not rebuilt). H4 checked. The bare `**[ON SCREEN]** Unverified.` draws nothing; the caveat is read (L108). Fix-list (legibility): checked. | Inherited headline "Incident 2: the root cause" over the try-it (4:12, after the reveal). |
| **V190** Drill: 500 unrelated changes | 15:34 | 68 MB | 25 % | PASS | The director note "Replay `labs/run incidents/lab-37-3-pr-500-changes` and show the snippet `consequence`." was read aloud and stood on the prediction card (9:54 to 10:20): the sentence removed (the lab name stays in the terminal title); the pause now shows "reverted instead of removed" (9:54 to 10:14). H4 checked. Fix-list (legibility, about 10 commits): checked. | None seen. |
| **V191** CI fails on Actions, senior standard 3 | 16:23 | 72 MB | 31 % | PASS | Nothing changed (not rebuilt). Fix-list: the hook now reads unambiguously ("This failure repeats identically, and it has failed on every run for five days"); the runner's clone uses the "absent from this clone" style: closed, checked. "Nothing was captured from GitHub" read in the introduction. | Section 30.18 table page 1 stands 3 s silent (3:21; the next paragraph is one bold lead-in sentence). |
| **V192** A secret is committed, senior standard 2 | 19:56 | 86 MB | 35 % | PASS; warn C1/C2 | Director note "Point at the first column ... Point at the last line" read aloud (8:22): "Look at ...". The three claims are marked only after the pause (4:00). | The six-step DIAGRAM is converted by the library into a two-row table whose cells merge lines of the drawing (8:22 to 8:35; library #2). Pace warning: section 7. |
| **V193** Incident summary, postmortems, controls | 16:19 | 74 MB | 27 % | PASS | Director note "Point at four things." read aloud (7:57): "Look for four things." Fix-list (quiz over a table): the release-job quiz has its own A/B/C card: closed, checked. | The timeline question "how long from publication to detection?" is asked over the timeline, by design (it is a reading question). |
| **V194** Gate briefing: production debugging | 11:36 | 48 MB | 32 % | PASS | Nothing changed (not rebuilt). Fix-list (`git ls-remote`): the narration says "the third one contacts your remote": closed, checked. | None seen. |
| **V195** CTO interview series | 16:06 | 73 MB | 31 % | PASS | Nothing changed (not rebuilt). The hook question is not answered on screen, as the script says. | None seen. |
| **V196** Final test briefing | 12:49 | 54 MB | 29 % | PASS | Item-type table page 1 stood 3 s silent (2:00): paragraph split, no word changed. Fix-list: the points quiz is on its own card after the table; the prediction stands before the transcript: closed, checked. | Table page 1 is now narrated but on screen only 1.8 s (2:00). The "Count" column head wraps to "COUN/T" (library #4). |
| **V197** Capstone briefing | 17:53 | 80 MB | 25 % | PASS | Nothing changed (not rebuilt). No capstone answer is shown: the D-findings quiz asks about scoring, not about a finding. | None seen. |
| **V198** Capstone debrief | 19:32 | 89 MB | 25 % | PASS | Nothing changed (not rebuilt). Answers appear only in the replay of each stage, after the "score it first" pause, as the script says. | None seen. |
| **V199** The road to Git 3.0 | 22:05 | 97 MB | 36 % | PASS | Table of section 14D.2 (sources and status) stood 7.5 s in silence (4:02): one sentence made of its status column ("The first row is official, the second is primary, read through a mirror, and the last three are secondary."). The quiz card was blank for 8 s before its question appeared: question now at 30 % (blank 3.8 s, 5:28). Hedges on screen checked everywhere: "planned", "as listed in BreakingChanges", "announced", "reported only", "the planned default"; the GitHub SHA-256 caveat is read. Fix-list ("predict two ways"): has a pause and "Lab 42.1 is where you check them": closed, checked. | Key-point number "2 REPOSITORIES" (15:31; true, library #1). |
| **V200** git history, git replay, git last-modified, git repo | 20:21 | 88 MB | 24 % | PASS | State table of section 14D.6: pages 1 and 2 stood 3 s each silent and "Read the Remote cell of the first row" was read over page 3 (3:39 to 3:53). Two sentences made of the table's cells added (fixup, `--dry-run`); each page now has its sentence (3:39, 3:47, 3:53). "Experimental" is on every scene title and card. Fix-list: the `1653f1a` / `863b8b5` sentence (different committer times) and "needs Git 2.54 or newer ... an older Git reports an unknown command" are in the script: closed, checked. | "Replay labs/run ch09/replay-conflict." is spoken and shown on the key point (about 14:00): an instruction to the viewer, left. |
| **V201** Release notes, patch workflow, farewell | 20:36 | 91 MB | 33 % | PASS | Nothing changed (not rebuilt). Rust in 3.0 is "planned" and "waits" on the milestones scene. The farewell is read and on screen (20:27 to 20:37). Fix-list: every material named in the farewell exists (`reference/references.md`, `reference/glossary.md`, `playbooks/`, the weak-area tracker in section 12 of the roadmap, `labs/`, `incidents/`): closed. | The `format-patch` transcript finishes typing only at the end of its 5 s sentence (12:01 to 12:06). |

### Imperfections that apply to several videos

1. **Director notes read aloud** (V182, V185, V190, V192, V193): all reworded or removed; a scan of the text given to the voice finds no "point at", "show the snippet" or "replay ... and show" in a director's sense any more (V197 "Point at the two merge commits" is addressed to the viewer).
2. **Tables held in silence**: 13 places (V179 cards, V181, V182 four pages, V183, V184, V185 two, V186 rows never shown, V196, V199, V200 two pages): each now has a sentence, by splitting a paragraph or by one sentence made of the table's cells. One left: V191 3:21.
3. **Inherited headlines** on key points after a bold lead-in (library #3 of batch 5B): left in V180, V181, V187, V189 and others; none of them shows a cause early or contradicts the sentence.
4. **Key-point big numbers** (library #1): "3 WAYS" (V194), "3 BRANCHES" (V200), "2 REPOSITORIES" (V199): all true; none wrong.
5. **Explainer share**: 20 to 36 %; V180 and V188 (20 %) are the lowest, none below a fifth.

## 3. Incident causes and answers (H3, H4), checked first

| Video | Where the script reveals | What the screen shows before it |
|---|---|---|
| V180 | The test of the four hypotheses, after the "write three hypotheses" pause (11:01) | Symptom terminal, the ten commands with their outputs (which are the evidence, by design), "What we know so far" with the observed behaviour only (6:50); hypothesis cards unmarked until 11:40; root-cause box at 11:51. |
| V181 | Worked case: the mechanism is taught in CONCEPT and DIAGRAM by design (no viewer diagnosis is asked) | Hook cards mark the three wrong explanations; nothing else early. |
| V186 to V190 | CONCEPT, after the introduction's "If you haven't, stop the video here" pause and "The cause is named in the next section" | Hook and introduction show only the reports and quizzes about records (no cause); the DIAGRAM section shows only "What we know so far" cards with the reports; the cause pictures appear in the demo. V187 and V190 hook quizzes are marked only in CONCEPT or after the pause with an answer that names no cause. |
| V191 | After "Before I name the cause, name it yourself" (3:57) | The evidence table and the "flaky" test only; the clones picture follows the pause. |
| V192 | CONCEPT, step 2, after the "true or false?" pause (3:28) | The three claims, unmarked. |
| V193 to V198 | Quizzes and interview questions | Every quiz has its own card, marked after the pause; every interview section holds only the question card during the pause; no test or capstone answer is shown beyond the script. |

## 4. Fix-list and final-pass items

| Item | Outcome |
|---|---|
| V180, V186 to V190 (priority): cause before the reveal | **Checked in the built videos** (section 3): the pre-demo pictures show only the symptom. |
| V180 director notes read aloud | **Closed** by the scene pass; checked in the spoken text. |
| V182 "any file in capitals" | **Closed** (section 2). |
| V179, V186, V190 section openers dropped | Noted only. |
| V188, V189, V190 graph legibility | **Checked** at 720p; one near-touch in V188 (section 2). |
| V184 catalog group names | **Closed**: defined in the narration. |
| V191 hook wording; runner's clone style | **Closed**, checked. |
| V193, V196 quiz over a table | **Closed**: each quiz has its own card after the table. |
| V194 `git ls-remote` | **Closed**: the narration says it contacts the remote. |
| V196 predict before the check | **Closed**: the prediction stands before the transcript. |
| V199 "predict two ways" | **Closed**: pause and pointer to Lab 42.1. |
| V200 `1653f1a` versus `863b8b5`; `git history -h` version | **Closed**: both sentences are in the script and spoken. |
| V201 farewell materials | **Closed**: all exist. |
| Final pass (02:10): quoted `[ON SCREEN]` hook naming a textbook section drawn as a textbook box | **Checked** for V179 to V201: no quoted hook names a section or chapter. |
| All ranges: no diagram held in silence; caveats read | **Checked** (sections 2 and 3); the caveat scan finds no shown-and-unread caveat. |
| All ranges: one wording per term | **Open** (final pass, with the glossary). |

## 5. Other things corrected

- After each edit `python3 tools/inject.py --check` reported 0 problems for the script; `python3 tools/check_course.py` reports 0 problems at the end.
- Narration growth (paragraph words): V185 2.0 %, V182 1.3 %, V184 0.8 %, V200 0.8 %, V186 0.7 %, V199 0.6 %; V190 −0.3 %; V179, V181, V183, V192, V193 and V196 unchanged in count. No fact was added: every new sentence is made of the cells of the table or scene on screen, or of the same paragraph.
- Changed: `[ANIMATION]`/`[PAUSE]` lines (V179 one `end` removed; V185 one `cards` tag added and one `[PAUSE]` moved; V199 one `at_1` value), narration sentences named in section 2, and paragraph splits. No snippet, table, heading or on-screen direction was touched. Nothing in `tools/` was edited.
- Every edited script was storyboarded in a scratch sandbox first: 0 warnings, 0 hints. The scripts as they were before this pass: `video/production/.cache/inspect-b6/orig/`.

## 6. What was verified by looking, and what was not

Verified in frames of the finished videos: every item in the "What was fixed" column, in the rebuilt MP4; that no incident cause and no test or capstone answer is on screen before the script's reveal (section 3); the absence of overlapping or cut text and of literal underscores at the sampled moments, except where listed; that every interview question holds only its question card during the pause (all 23); that quizzes, predictions and try-its are not asked over a picture that shows their answer at the sampled moments (V185 fixed; V193 timeline question by design); that every Git 3.0 plan and every experimental command carries its hedge on screen at the sampled moments (V199 to V201).

Not verified: frames between the samples; the unchanged parts of a rebuilt video after its rebuild; the audio; the subtitles beyond the scans of section 7 and the QC tool's checks; checklist items A13, C6, C7, E9 (need ears), F9, F10, G4, G5 and I8 to I10 (player, chapter clicks, thumbnails, upload).

## 7. The sound (not listened to)

Nobody listened to any of the 23 videos. What could be established without ears:

- `make.sh qc V179-V201`: 23 PASS. Loudness, peak, clipping, silence and the pace of every beat are inside the tool's bounds or accepted under the three-identical-takes rule; every voice clip has its verification mark.
- **Clips accepted under the three-identical-takes rule, to be listened to once:**

| Video | Time | Sentence | Measured |
|---|---|---|---|
| V187 | 10:16 | "The commits are there." | 4.44 words/s, 20.0 letters/s (4 words in 0.90 s) |
| V192 | 9:00 | "Find. SAFE." (spoken from "Find. 🟢 SAFE.") | 1.30 words/s, 5.2 letters/s (2 words in 1.54 s) |

- Places worth one listen although the tool does not flag them:
  - **V182, 7:07 to 7:33**: the five new row sentences with state-file names ("MERGE_HEAD", "the rebase-merge or rebase-apply directory", "CHERRY_PICK_HEAD", "REVERT_HEAD", "BISECT_LOG and BISECT_START").
  - **V185, 3:27 to 3:43**: the two new page sentences ("git ls-remote origin", "a dangling blob").
  - **V200, 3:39 to 3:58**: "fixup" and "dash dash dry-run" in the new sentences; and **about 14:00** "Replay labs slash run C H 9 slash replay-conflict".
  - **V199**: "shah" for SHA (17 times); `WITH_BREAKING_CHANGES` is given to the voice as "WITH BREAKING CHANGES" in capitals (about 3:20).
  - **V180, about 13:20**: the commit ID spoken as "3 0 e 8".
  - **V201, 20:27 to the end**: the farewell.
- The voice builds: 13 builds, each at the first attempt, while the main run voiced V196 to V201 under the same voice lock.
- **The text given to the voice** (`.cache/tts/VNNN.spoken.txt`, all 23) was scanned for presenter notes; the five found were fixed (section 2).

## 8. Library defects and limits found (nothing in `tools/` was edited)

| # | Where seen | Defect | Workaround used |
|---|---|---|---|
| 1 | V192 8:22 | A wide `[DIAGRAM]` text drawing (six columns of steps) is turned into a two-row table whose cells join separate lines of the drawing ("for the first push" and "at the provider: was it used?" read as one item). | none (the drawing is a direction, not changed) |
| 2 | V187 11:02 to 11:50 | In a `graph` with `note:` labels, the edges of a merge pass through the notes ("Asha: cap", "Asha: halve the rate"). | none |
| 3 | V196 2:00 | Narrow table columns wrap a short head inside the word ("COUN/T"; same as batch 5B #5). | none |
| 4 | V181, V182, V183, V185, V191, V196, V200 | A paged table pages only on paragraphs: a page with no paragraph of its own stands 3 s in silence, and a sentence about an earlier row can land on a later page (V200). | paragraph splits and one sentence per page |
| 5 | V184 7:27 | `walk` column heads are split on every comma, so a head written `stop,_and` becomes two heads. | none (the tag reads as intended otherwise) |
| 6 | V179 3:42, V199 5:28 | `cards` with `at_N` times show an empty frame until the first mention; with the question at a late `at_1` the quiz is blank for several seconds. | `at_1` moved earlier in V199 |

## 9. Verification at the end

- `make.sh qc V179-V201` at about 09:13: 23 PASS, 0 failed. ffprobe and `VNNN.build.json` for all 23: section 1; the script hash in every storyboard equals the script on disk, and every MP4 is newer than its script.
- Storyboards: no warning and no hint for any of the 23. `python3 tools/check_course.py`: 0 problems.
- Disk: 11 to 13 GB free throughout (stop set at 6 GB).
- Rebuilds ran one at a time from a detached queue started with `setopt NO_BG_NICE`, 08:13 to 09:12. `--look` renders one at a time (prefix `b6-`); look folders and all frames are deleted. Logs: `video/production/.cache/inspect-b6/rebuild.log`; working notes: `video/production/.cache/inspect-b6-progress.md`.
- Times in this report are from the final builds.
- No `git` command was run in the course directory, nothing was run against GitHub, no video outside V179 to V201 was touched, and nothing in `tools/` was edited.

## 10. Ready to upload?

V179 to V201 are ready from the tool's and the eyes' side (QC PASS, inspected frames, fixes re-inspected, no cause or answer shown early, every Git 3.0 plan and experimental command hedged on screen). Before upload, a person should do the "ears" items, at least the two clips of section 7 (V187 10:16, V192 9:00) and the places listed there.
