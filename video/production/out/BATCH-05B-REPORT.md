# Batch 5B (V156 to V178): finishing report

Written 2026-10-09 by the finishing inspector of V156 to V178 (Actions security, credentials, secret scanning and leak response; history rewriting and the security gate; team workflows; Git for ML projects). Voice: the macOS voice Tara at 165 words per minute. Every video carries the animation layer and was voiced with the repaired voice step. The form follows `BATCH-05A-REPORT.md`.

## 1. Result

- **23 of 23 videos built, 23 of 23 PASS from the QC tool** (`make.sh qc V156-V178`, run at 07:53 after the last build): 1920x1080, 30/1 fps, H.264 and AAC, picture and sound equal within 0.012 s, built from the script as it is now, storyboards with no warning and no notice. Warnings: subtitle line length (E5, all 23) and reading speed (E6, all 23); one pace warning (C1/C2, three identical takes) in V177 (section 7).
- Total length 7 h 41 min, 2.08 GB. Files: `video/production/out/VNNN.mp4` with `.srt`, `.chapters.txt`, `.build.json`; QC reports in `video/production/out/qc/`.
- **At the start** (04:27): V162 had no MP4 (its voice build had failed on 'Nx, "s1ngularity", August 2025. Source: the project's post-mortem.' before the 01:50 rule fix). Of the other 22, 20 passed and two failed: **V157** (C3: the raw symbol in the quoted "read/write", final-pass item 3) and **V177** (C1/C2: "Back every hook with a C I check." 8 spoken words in 1.76 s, 4.55 words/s against 4.54; the builder had judged the clip inside the bounds).
- **V162** was voiced first, alone (04:27 to 04:37): the sentence was spoken at the first attempt, QC PASS. It was rebuilt again later with its script fixes.
- **20 videos were rebuilt in full** (storyboard, slides, animate under `nice -n 20`; voice at normal priority; QC niced; one at a time from a detached queue started from a shell with `setopt NO_BG_NICE`): V156 to V167, V169, V170, V173 to V178. Each was built once. **Every voice build succeeded at the first attempt; no sentence was refused.** The queue was first started at nice 5 by mistake (the outer shell's background nice); it was killed during V162's animate step at 04:57 and restarted correctly. It stopped itself at 05:59 after V166 when free disk fell to 7 GB (another process on the Mac, see section 8) and was restarted at 07:06 with a 6 GB stop for the remaining eight.
- **Not rebuilt:** V168, V171, V172 (builds of the main voice run of 9 Oct; nothing needed changing).
- **How they were inspected.** From frames of the finished MP4s with the script, the storyboard and the `.srt` open: the last moment of every explainer-scene beat, the middle of each long scene, every ASCII drawing, every silent hold and prediction pause, and six frames spread over the length: 21 to 71 frames per video, about 800 in all, looked at as contact sheets of six half-size frames, with strips and crops where a sheet left a doubt (about 60). Storyboard scans by script for: silent holds on non-terminal slides, callouts under unrelated narration, late steps, inherited key-point headlines, caveat words on screen and in nearby narration, interview sections (all 23 hold only the question card). After each rebuild the changed places were looked at again in the new MP4 (1 to 7 frames each, about 75 in all); the unchanged parts of a rebuilt video were not looked at a second time. New or changed scene tags were checked with `--look` first (prefix `b5b-`, one at a time, 3 renders).
- **Not done: nobody listened.** No audio was heard at any point. Section 7 lists what was done for the sound.

"Explainer scenes" is the share of the running time during which a library scene or an animated commit graph is on screen. "QC tool" is the result of `make.sh qc VNNN`.

## 2. Per video

"Headline" means: the first sentence of the GitHub walkthrough paragraph was made a bold lead-in (no word changed), so its key points no longer carry the headline of the last terminal step. "Read" means: a caveat or drawing that stood on screen unread now has one sentence made of its own words.

| Video | Length | Size | Explainer scenes | QC tool | What was fixed | Still imperfect |
|---|---|---|---|---|---|---|
| **V156** Actions security model, job token, permissions | 19:43 | 88 MB | 30 % | PASS | Trust picture (DIAGRAM) stood 7.9 s in silence: one sentence from its direction (11:43). Walkthrough replay of the three layers ended on the caption "The token of that job only" while "find the setting Workflow permissions" was read: now stops at step 1 with the setting's caption (15:18). Headline (15:04). "2 February 2023" spoken in words. Fix-list (hook terms): closed by the scene pass, each term is defined in the hook. | Hook shows the 21A.1 question (stated in the script) rather than the CTO quotation (library #2 type). Introduction key-point cards are sparse. |
| **V157** Fork pull requests, privileged triggers | 20:29 | 97 MB | 26 % | PASS (was FAIL C3) | Quotation now 'is granted read and write repository permission, "even when it is triggered from a public fork"' (final-pass item 3, C3). Two-lanes table header stood 4.7 s in silence: one sentence (13:06). "2 November 2026" in words (two places). | The caption "The token is read/write ..." stays on screen (not spoken). |
| **V158** Script injection | 16:35 | 72 MB | 25 % | PASS | Root-cause box of 21A.6 stood 7.2 s in silence: its root-cause line read (8:41). Fix-list (three new lines): closed by the scene pass. | None seen. |
| **V159** Third-party actions, pins, policies | 17:35 | 76 MB | 25 % | PASS | "Unverified" callout (immutable actions) under an unrelated paragraph, never read: read (5:56). Tag graph 7.9 s silent: one sentence (9:53). State table of 21A.7 two pages silent: one sentence per page (12:30, 12:35). A caption overlapped the "sixty repositories" chip: removed (15:18). "2 November 2026" lead-in in words. | The callout card drops the roadmap sentence (library #3); it is neither shown nor read. |
| **V160** Secrets, OIDC, caches, runners, environments | 23:20 | 99 MB | 28 % | PASS | OIDC caption "THE ACCESS DECISION IS MADE HERE" sat over GitHub's provider: now "The access decision is made at the cloud provider" (shown only after the quiz is answered, 7:00, 12:59, 14:34; look `b5b-v160o`). Fix-list (second DIAGRAM "no" callout): closed, the direction now renders nothing and the narration is read over the replay. | DIAGRAM mask picture plays three states in 7.7 s. |
| **V161** Static analysis, platform changes, workflow 12, agents | 24:32 | 119 MB | 21 % | PASS | "Unverified" callout (holds on suspicious runs) never read: read (6:39). Headline: "Lab 29.3 is done in the lab shell; its product is a file, review.md." (18:54; "and" became a semicolon). Key-point number "12 AS": reworded ("Hold workflow 12 in mind"). | None seen. |
| **V162** Case studies | 19:12 | 85 MB | 50 % | PASS (was not built) | Final-pass item: built, the sentence voiced. The direction "the table of section 21A.18, one row at a time" was drawn as the textbook table paged over the tj-actions narration: Nx, Trivy and an "Aqua notice" card stood under tj-actions sentences, four pages 3 s each in silence. The table was removed from the direction (now "Lower third: GitHub Actions.") and tj-actions got its own table scene in the script's own words, like the other eight cases (2:45 to 3:26; look `b5b-v162tj`). Pattern drawing 11.3 s silent: one sentence from its direction (12:31). "11 May 2026" lead-in in words. Key-point number "2 OF ITS": reworded. Fix-list: every case card matches the script's figures and attributions (numbers in every case table checked against the narration). | None seen. |
| **V163** The Git client, three guards | 20:33 | 91 MB | 26 % | PASS | "Outdated advice" callout (safe.directory star) under the next topic, never read: read (5:28). | Protocol table header alone for 18 s (6:13 to 6:31). |
| **V164** Credentials, what deletion does not remove | 20:41 | 96 MB | 26 % | PASS | The three-cases table ran one paragraph behind the narration (header only during April 2022, row 3 after May 2026 had been read): paragraph split in three with steps, no word changed (4:59 to 5:38). Root-cause box of 21B.10 6.4 s silent and the 21B.11 table 7.5 s silent: one sentence each (11:47, 15:49). Fix-list (side branches): the scope graph draws `54093fe` and `7fae871`; the first graphs show main only, as the narration says. | Graph IDs small at nine commits (12:57 to 15:09). |
| **V165** Secret scanning, push protection, Dependabot | 23:46 | 104 MB | 18 % | PASS | "Unverified" callout (OpenAI, partner notifications) 44 s under the Scanners paragraph, never read: read (6:48). Headline (17:57). | The "bypass" chip touches the zone label "YOUR MACHINE" (11:13, 15:03; library #4). Explainer share 18 %. |
| **V166** Leak response, case studies | 21:50 | 106 MB | 33 % | PASS | Table of 21B.14: page 1 stood 3 s silent and "Step 1: contain" was read over page 2: one sentence added ("After it come assess, eradicate, recover, communicate and prevent."), so each page is read (3:05, 3:09). Times spoken in words (09:14 etc. are on-screen labels). | Case table of 21B.15 runs one page behind the narration (Microsoft and Hugging Face read over page 1; library #2b, could not be fixed without rewording). 16:02 key point keeps the headline "Step 2: assess". |
| **V167** History rewriting | 22:50 | 101 MB | 24 % | PASS | Fix-list "only the parent differs": not drawn anywhere; the rewrite table (14:05 to 14:26) shows ".env removed" and the parent in every row, the narration gives both reasons. Recap caption "Shared up to 987a49d ..." was drawn on the replayed plan scene: the rewrite graph now returns for it (21:26). State table of 21B.17: page 1 3 s silent: paragraph split (17:25, 17:31). | The bare "Unverified." direction draws nothing (the caveat is read, 5:47). Table cells wrap "unchange/d" in the narrow Index column. |
| **V168** Stale clone, GitHub side, controls | 19:35 | 90 MB | 23 % | PASS | Nothing changed (not rebuilt). Fix-list (merge base): graphs start from "...older". | DIAGRAM quiz is read over the graph that shows the answer path, by design ("Follow the upper parent"). |
| **V169** Gate briefing: Security | 10:18 | 43 MB | 26 % | PASS | "Look at the tag, the last line of the output." was read while the terminal was still typing its second command and the graph replaced it: a pause after it, the last line is now on screen before the graph (5:51 to 5:56). Fix-list "13 of 20": checked against `assessments/gate-8-security.md` (at least 70 % per part, so 14 of 20 is the minimum): the quiz is right. | Quiz key point keeps the section headline "How it is built". |
| **V170** Fork workflow | 20:12 | 91 MB | 23 % | PASS | Quiz "rebase or merge after review started?" was asked over the 27.3 table whose fourth row ("stay attached") is the answer: now its own question card with A/B, marked after the pause (12:30, 12:44; look `b5b-v170q`). Headline (14:41). Fix-list (`a83a713`): reflog-only style used. | None seen. |
| **V171** Branching strategies | 19:50 | 86 MB | 27 % | PASS | Nothing changed (not rebuilt). Fix-list: terminal direction says two features before the release, a third after; "branch by abstraction" is not defined in the textbook (ch27 line 483 names it only), left undefined. Hedge on the 2020 note ("as the research report summarizes it, not as a quotation") on the card and in the narration. | Trunk-based graph labels tiny at 720p (9:14, 12:22). |
| **V172** One release, one hotfix | 19:33 | 87 MB | 26 % | PASS | Nothing changed (not rebuilt). Fix-list: graphs use "...older" and draw side commit `5928b76`. | None seen. |
| **V173** Flags, merge queues, stacks, evidence | 18:07 | 78 MB | 34 % | PASS | Decision table of 27.14: page 1 3 s silent: paragraph split (10:51, 10:56). Key-point number "40 ENGINEERS RUNS": reworded to "... forty engineers that runs ..." (12:12). Hedges kept on screen and spoken: DORA "is associated with", "one study of one population", "reports", "described". | None seen. |
| **V174** Practices, anti-patterns, review, messages | 18:36 | 85 MB | 25 % | PASS | Practices table: page 1 silent and its rows read over page 2; anti-patterns table: page 1 silent: two paragraph splits, the "Required checks" sentence moved before the force-push one, no word changed (2:39 to 3:07). | Configuration file pages 3 s each silent (13:35; a transcript). |
| **V175** What belongs in Git, notebook filter | 20:02 | 91 MB | 24 % | PASS | State table of 28.4 (one row per page): three pages silent and "the third row" read after it had left: one sentence per row, rows 1 and 2 from the table's own cells (13:05 to 13:26). | None seen. |
| **V176** Data and model versioning, reproducibility | 20:58 | 96 MB | 20 % | PASS | Tools table of 28.6: two pages 4.1 s each silent: "The table is from the course's research report ..." moved after the table and "Two flags are carried from the report." before the caveat, no word changed (3:29, 3:31). Fix-list (trees with one ID): renders `aa18ad2` under HEAD as intended. | Page 2 of the tools table on screen only 2.6 s. "The real tools" card 1.2 s and mostly empty. |
| **V177** Ignore and attributes, hooks backed by CI | 20:13 | 91 MB | 20 % | PASS (was FAIL C1/C2); warn C1/C2 | Objective 4 now "Back every hook with a check in CI." (same meaning). | Its clip is accepted by the three-identical-takes rule (4.59 words/s): listen. Explainer share 20 %. |
| **V178** CI for ML, evaluations, serving, secrets, agents | 22:54 | 105 MB | 26 % | PASS | Key-point number "24 NEW SECRETS" (taken from 28,649,024, a wrong fact on screen): reworded ("as the report gives it", 10:48). The 28.15 table's caveat "the report's inference" was only in the direction: now read (12:00). Fix-list ("MCP" undefined): the textbook gives no definition, left. | None seen. |

### Imperfections that apply to several videos

1. **Caveats shown and not read** (V159, V161, V163, V165, V178): all read now. A bare `**[ON SCREEN]** Unverified.` direction draws nothing (V167, V176); the narration there carries the caveat.
2. **Tables and drawings held in silence**: in 15 places (V156, V157, V158, V159 two, V162 two, V164 two, V166, V167, V173, V174 two, V175, V176): each page or drawing now has a sentence, mostly by splitting an existing paragraph.
3. **Inherited headlines on GitHub walkthroughs**: fixed in V156, V161, V165, V170. The same mechanism leaves section headlines on quiz and try-it cards ("How it is built", "Branch names are conventions, not laws", "Step 6: what ships ..."); these were not changed.
4. **Key-point big numbers** (library #1): four found and reworded (V161, V162, V173, V178). Scanned with the library's own function over all 23 storyboards; the remaining numbers ("Five mistakes", "Three rules", "40 engineers") are right.
5. **Explainer share**: 18 to 50 %; V165 (18 %), V176 and V177 (20 %) and V161 (21 %) are below a quarter.

## 3. Fix-list and final-pass items

| Item | Outcome |
|---|---|
| Final pass: V162 failed its voice build on 'Nx, "s1ngularity", August 2025 ...' | **Closed.** Voiced at the first attempt at 04:37, again in the full build at 05:01; QC PASS. |
| Final pass 3: C3 flags V157 "read/write" | **Closed** by rewording (section 2). |
| V162 case cards must match the script's figures and attributions | **Closed.** The textbook table (which showed rows and a source the narration had not reached) was replaced; every case table is the script's own words; numbers checked. |
| V167 must never show "only the parent differs" | **Checked**, not drawn (section 2). |
| V171 and V173 hedges and attributions | **Checked**, on screen and spoken (section 2). |
| Times and dates spelled in words (V162, V166) | **Checked** in the subtitles and the spoken text; five digit dates in V156, V157, V159 and V162 changed to words. On-screen table labels keep their digits. |
| V156 hook terms; V158 three lines; V160 "no" callout; V164 side branches | **Closed** (section 2). |
| V160 version labels | Card labels are the script's own words; not changed. |
| V168, V172, V174 merge base | **Closed** by the scene pass ("...older"). |
| V169 "13 of 20" | **Verified** against the gate file. |
| V170 `a83a713` reflog style; V176 one-ID trees; V171 terminal direction | **Closed.** |
| V171 "branch by abstraction", V178 "MCP" | **Left undefined**: the textbook has no definition. |
| V156 to V166: interview question on screen only | **Checked**, all 23 videos hold only the question card during the pause. |
| All ranges: no diagram held in silence; caveats read | **Checked** from the storyboards and frames (sections 2 and 3). |
| All ranges: one wording per term | **Open** (final pass, with the glossary). |

## 4. Other things corrected

- After each edit `python3 tools/inject.py --check` reported 0 problems for the script; `python3 tools/check_course.py` reports 0 problems at the end.
- Narration growth (paragraph words): V159 2.2 %, V164 1.2 %, V175 1.2 %, V163 1.1 %, V162 1.1 %, V165 1.1 %, V156 1.1 %, V158 0.6 %, V161 0.5 %, V157 0.5 %, V178 0.3 %, V166 0.3 %; others under 0.1 % or 0. No fact was added: every new sentence is made of the words of a callout, a root-cause box, a table, a direction or the same paragraph.
- Changed: `[ANIMATION]`/`[PAUSE]` lines, narration sentences named in section 2, bold markers, and three on-screen directions: V162 (the 21A.18 table direction shortened to its lower third), V159 (one `say:` removed), V160 (one caption). No snippet, YAML, table or heading was touched. Nothing in `tools/` was edited.
- Every edited script was storyboarded in a scratch sandbox first: 0 warnings, 0 hints. The scripts as they were before this pass: `video/production/.cache/inspect-b5b/orig/`.

## 5. What was verified by looking, and what was not

Verified in frames of the finished videos: every item in the "What was fixed" column, in the rebuilt MP4; the absence of overlapping or cut text and of literal underscores at the sampled moments, except where listed; that no interview question is followed by an answer picture (all 23); that quizzes, predictions and try-its were not asked over a picture that shows their answer at the sampled moments (V170 fixed; V168 is a reading question by design); that scene captions fit the paragraph being read at the sampled moments (V156, V160, V167 fixed).

Not verified: frames between the samples; the unchanged parts of a rebuilt video after its rebuild; the audio; the subtitles beyond the scans of section 7 and the QC tool's checks; checklist items A13, C6, C7, E9 (need ears), F9, F10, G4, G5 and I8 to I10 (player, chapter clicks, thumbnails, upload).

## 6. Library defects and limits found (nothing in `tools/` was edited)

| # | Where seen | Defect | Workaround used |
|---|---|---|---|
| 1 | V178 10:25, V161 12:22, V162 19:02, V173 12:16 | `find_count` in `video_animate.py` draws any "number + plural word" near the start of a key point as a big number: "24 NEW SECRETS" from 28,649,024, "12 AS", "2 OF ITS", "40 ENGINEERS RUNS". The first is a wrong fact on screen. | rewording |
| 2 | V162 2:45 | A direction that names a textbook table "one row at a time" pages that table over the paragraphs that follow even when no paragraph names a row: pages are spread over unrelated narration and the unmatched first pages stand in silence. | own table scene |
| 2b | V166 7:27 | In a paged table, a narration paragraph before the first row is counted toward paging, so every page lags one paragraph (Microsoft and Hugging Face read over page 1). Moving the paragraph or merging paragraphs did not help. | none; open |
| 3 | V159 5:46 | `quote_callout` drops the text after the second quotation mark (the roadmap sentence of the Unverified callout). | the shown part is read |
| 4 | V165 11:13, 15:03 | In `gates` with zones, the "bypass" chip touches the zone label. | none |
| 5 | V167 17:20 | State tables wrap "unchanged" inside the word in the narrow Index column ("unchange/d"). | none |
| 6 | V177 2:16 | The builder judges a beat's clips, QC the whole beat: a beat of 7 + 1 spoken words falls under the short-beat rule in the builder and the long-beat rule in QC (V177 failed QC with a clip the builder had accepted). | rewording |
| 7 | V167, V176 | A bare `**[ON SCREEN]** Unverified.` draws nothing. | narration carries the caveat |

## 7. The sound (not listened to)

Nobody listened to any of the 23 videos. What could be established without ears:

- `make.sh qc V156-V178`: 23 PASS. Loudness, peak, clipping, silence and the pace of every beat are inside the tool's bounds or accepted under the three-identical-takes rule; every voice clip has its verification mark.
- **Clip accepted under the three-identical-takes rule, to be listened to once:**

| Video | Time | Sentence | Measured |
|---|---|---|---|
| V177 | 2:16 | "Back every hook with a check in CI." | 4.59 words/s, 13.8 letters/s |

- Places worth one listen although the tool does not flag them:
  - **V162, about 4:45**: 'Nx, "s1ngularity", August 2025. Source: the project's post-mortem.' (the sentence of the final-pass item).
  - **V157, about 6:30**: the reworded quotation "is granted read and write repository permission, "even when ...".
  - **V178**: "a full commit shah" (SHA as the voice says it).
  - **V158, 3:00 to 3:30**: "dollar sign and double braces".
  - **V163**: "safe dot bare Repository equals explicit".
  - **V172**: "v 1 point 4 point 0"; **V170**: "upstream main two dots HEAD".
- The voice builds: 21 builds (V162 twice), each at the first attempt, while the main run worked on V179 onward under the same voice lock.
- **The text given to the voice** (`.cache/tts/VNNN.spoken.txt`, all 23) was scanned for presenter notes (none: "point at" occurs only as English) and symbol wording; odd but consistent wordings: "dot yammel" for .yml, "dot git hub slash workflows slash", "labs slash run C H 21 A slash ...", "dash dash" for options.

## 8. Verification at the end

- `make.sh qc V156-V178` at 07:53: 23 PASS, 0 failed. ffprobe and `VNNN.build.json` for all 23: section 1; the script hash in every storyboard equals the script on disk, and every MP4 is newer than its script.
- Storyboards: no warning and no notice for any of the 23. `python3 tools/check_course.py`: 0 problems.
- Disk: 10 to 14 GB free at the start. At about 06:36 another process on the Mac took free space down to 3 GB; my queue had already stopped itself at 05:59 with 7 GB free (its stop was then 8 GB) after V166. Restarted with 14 GB free and a 6 GB stop; 13 GB free at the end.
- Rebuilds ran one at a time from a detached queue started with `setopt NO_BG_NICE` (after the false start described in section 1), 04:57 to 07:51. `--look` renders one at a time (prefix `b5b-`); look folders and all frames are deleted. Logs: `video/production/.cache/inspect-b5b/rebuild-0.log`, `rebuild-1.log`, `rebuild.log`; working notes: `video/production/.cache/inspect-b5b-progress.md`.
- Times in this report are from the final builds.
- No `git` command was run in the course directory, nothing was run against GitHub, no video outside V156 to V178 was touched, and nothing in `tools/` was edited.

## 9. Ready to upload?

V156 to V178 are ready from the tool's and the eyes' side (QC PASS, inspected frames, fixes re-inspected). Before upload, a person should do the "ears" items, at least the V177 clip of section 7 and the places listed there.
