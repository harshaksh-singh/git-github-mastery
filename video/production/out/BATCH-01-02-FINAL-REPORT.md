# Batches 1 and 2 (V010 to V066, without V020, V022, V025): final inspection report

Written 2026-10-09 by the finishing inspector of V010 to V066 after every video was voiced again with the repaired voice step. V020, V022 and V025 belong to the automatic final pass and were not touched. Voice: the macOS voice Tara at 165 words per minute. The form follows `BATCH-06-REPORT.md`.

## 1. Result

- **54 of 54 videos built, 54 of 54 PASS from the QC tool** (`make.sh qc V010-V066`, run at about 11:50 after the last build; that run also passed V020, V022 and V025, rebuilt by the final pass): 1920x1080, 30/1 fps, H.264 and AAC, built from the script as it is now (script SHA-1 of every storyboard and build equals the script on disk), storyboards with no warning and no hint. Warnings: subtitle line length (E5) and reading speed (E6) in most videos; **one pace warning** (C2, three identical takes) in V037 (section 7). No other C1/C2 warning in the range.
- Total length 14 h 44 min, 3.84 GB. Files: `video/production/out/VNNN.mp4` with `.srt`, `.chapters.txt`, `.build.json`; QC reports in `video/production/out/qc/`.
- **At the start** (09:30): the range passed QC except **V011** (C2 FAIL: beat 36, "Two pictures now. The textbook's analogy ...", had lost its verified mark) and **V037**, which had **no MP4 at all** (its voice build of 00:42 had failed on the pace rule before the three-identical-takes rule existed, so `qc all` listed it as "not built" and the final pass would not have built it).
- **21 videos were rebuilt in full**, one at a time from a detached queue started from a shell with `setopt NO_BG_NICE` (storyboard, slides, animate under `nice -n 20`; voice at normal priority; QC niced), 09:39 to 11:47: V010, V011, V012, V016, V017, V019, V027, V028, V031 (twice, see V031), V032, V033, V037, V042, V043, V047, V048, V049, V050, V058, V064, V065. **Every voice build succeeded at the first attempt; no sentence was refused.**
- **Not rebuilt:** V013, V014, V015, V018, V021, V023, V024, V026, V029, V030, V034, V035, V036, V038, V039, V040, V041, V044, V045, V046, V051, V052, V053, V054, V055, V056, V057, V059, V060, V061, V062, V063, V066 (nothing that a script edit within my rules could fix; their remaining defects are library defects, section 8).
- **How they were inspected.** Frames of the finished MP4s, laid out as captioned contact sheets (time, beat, section and the sentence being read under each frame): the last moment of every paragraph read over a scene, table, drawing or callout; the middle of every scene paragraph over 20 s and every paragraph over 30 s; every pause and every silent hold (middle); the frame just before every pause (what is on screen when the question is asked); six spread over the length. 25 to 59 frames per video, about 2,050 in all; strips of chosen times where a sheet left a doubt. Plus scans by script of the storyboards (silent holds of drawings, tables, pages; caveat words on screen; inherited headlines) and of the text given to the voice (`.cache/tts/VNNN.spoken.txt`) for director notes. After each rebuild the changed places were looked at again in the new MP4 (3 to 33 frames each, about 170 in all); the unchanged parts of a rebuilt video were not looked at a second time. V037, built for the first time, was inspected in full after its build.
- **Not done: nobody listened.** No audio was heard at any point. Section 7 lists what was done for the sound.

"Explainer scenes" is the share of running time during which a library scene (including the animated commit graph) is on screen, measured from the storyboard and the beat times. "Silent" means on screen with no sentence read over it.

## 2. Per video

| Video | Length | Size | Explainer scenes | QC tool | What was fixed | Still imperfect |
|---|---|---|---|---|---|---|
| **V010** Three trees, two views | 15:31 | 67 MB | 18 % | PASS | The drawings of 2.10 (two views of a commit) and 2.12 (clone and GitHub layers) stood 6.4 s and 9.2 s in silence (6:54): one sentence each, made of the drawings' own labels (6:54, 7:07). | The "how many versions of `rules.txt`" prediction (7:22) comes 1 min after the 2.9 drawing that shows them (recall, by design). |
| **V011** Working tree, three categories, status | 15:49 | 72 MB | 12 % | PASS | Voiced again (C2: a clip without its mark). The 4.4 status drawing stood 7.5 s silent (8:27): one sentence from its labels. Porcelain page 1 was silent: "The formats for scripts." split off as its own paragraph. | That page is now narrated but on screen only 1.6 s, still typing (11:57). |
| **V012** Ignore rules, already-tracked trap | 18:25 | 82 MB | 10 % | PASS | Root-cause box 4.6 stood 9.2 s silent (7:59): one sentence from its cells. | None seen. |
| **V013** restore, mv, rm, no renames | 16:34 | 71 MB | 18 % | PASS | Nothing changed. | None seen. |
| **V014** Modes, case, line endings, clean | 19:16 | 84 MB | 5 % | PASS | Nothing changed. | Low explainer share (5 %): transcripts carry the video. |
| **V015** The index | 14:04 | 63 MB | 22 % | PASS | Nothing changed. | The index-lines quiz (7:04) is recall of the DIAGRAM shown earlier. |
| **V016** Three diffs, add -p, intent-to-add | 16:02 | 69 MB | 11 % | PASS | `add-patch` 01 (two pages) and 02 page 1 stood 11 s silent (9:04 to 9:24) because the paragraph that describes the diff was read before the transcript: moved after it and split in two; "Answering ? ..." split from the try-it. No word changed. | `three-diffs` 02/03 type 12 s with no sentence (7:56, by design: the viewer predicts). |
| **V017** Deletions, renames, scope of add | 16:46 | 75 MB | 15 % | PASS | The prediction "what does `git commit src/retriever.py` record?" was asked over the previous transcript, whose last comment line gives the answer (12:18). A `cards` card "Now the surprise" with the question and the two states (look `b12-v017`) now carries the question and the pause (12:04 to 12:21). | The card frame is empty for the first 2 s (cards are timed to their place in the paragraph). |
| **V018** Reading the index, two bits, stat cache, lock | 18:25 | 82 MB | 8 % | PASS | Nothing changed. | **The callout reads "Unverified" and, under it, ", as a callout."** (5:08 to 5:21): the direction `**[ON SCREEN]** "Unverified", as a callout.` keeps its trailing words (library #1). The caveat is read. |
| **V019** What a commit is | 15:32 | 68 MB | 24 % | PASS | State table 6.3 stood 5.4 s silent, its detached-HEAD row never read (4:45): one sentence from its cells. | Remote and GitHub cells wrap as "unchange / d" (4:46; library #4). |
| **V021** Amend, empty commits, trailers | 16:35 | 72 MB | 15 % | PASS | Nothing changed. | None seen. |
| **V023** branch and switch | 16:09 | 67 MB | 18 % | PASS | Nothing changed. | Two transcripts type 9 s without a sentence (9:21). |
| **V024** Detached HEAD | 13:47 | 58 MB | 20 % | PASS | Nothing changed. | None seen. |
| **V026** Tags, branch names, stale branches | 17:06 | 70 MB | 9 % | PASS | Nothing changed. | None seen. |
| **V027** Configuration scopes | 17:22 | 81 MB | 4 % | PASS | Root-cause box 14B.3 stood 7.5 s silent at the end of the demo (13:00): one sentence from its cells. | Low explainer share. |
| **V028** Conditional includes, settings, aliases | 20:37 | 97 MB | 3 % | PASS | The 19-page settings table: 11 pages stood 3 s each in silence and the narration ran one or two pages behind the table (4:31 to 6:57). Now one sentence per page: five paragraphs split or reordered, seven short sentences made of the table's cells (`user.name`, `init.defaultBranch`, `push.default`, `diff.colorMoved`, `core.editor`, `core.autocrlf`, `core.excludesFile`, `commit.gpgSign`); `end` before the team rule. Every page has its own sentence. | A 31 s key point "A second one from the textbook." shows an empty card (17:27; library #3). |
| **V029** Gate briefing: fundamentals | 12:56 | 53 MB | 9 % | PASS | Nothing changed (only directions would need changing). | The direction "The table 'The four parts' from the assessment guide" draws a callout with those words instead of the table (2:12 to 2:58); key-point number "85 FOR THIS" (3:01); the `[TERMINAL]` direction with `On screen: "Warm-up ..."` is drawn as a callout labelled "labs/ch01/diagnosis.sh. On screen" (7:24). Library #1, #2. |
| **V030** Divergence, merge base, fast-forward | 14:13 | 61 MB | 20 % | PASS | Nothing changed. | Table page 1 3 s silent (5:49; library #4). |
| **V031** The true merge | 16:21 | 71 MB | 25 % | PASS | The root-cause box 8.5 stood 9.2 s silent **before the demo** and answered the later prediction "which temperature for each base" (8:14 vs 10:46); its later "Show the root-cause box" drew nothing. Now `step: grow` keeps the criss-cross graph on screen in place of the early box, and one sentence made of the box (root cause, prevention) is read over a key point after the demo (12:22). `content-merge` pages 1 and 2 were silent: the paragraph is split in three (9:44). Rebuilt twice: the first build's key point read "The root-cause box. ..." with no box drawn; the words "The root-cause box." were removed. | The box itself is no longer drawn anywhere (the library cannot bring a drawing back after the demo). |
| **V032** Strategies and why conflicts occur | 15:40 | 67 MB | 8 % | PASS | Both root-cause boxes (8.7, 8.6) stood silent before the demo (8:26 to 8:42), and the 8.6 box answered the `-X ignore-space-change` prediction (10:20); both later "Show the root-cause box" directions stood 8 s silent (10:29, 11:41). Now: one sentence over the 8.7 box; `step: merge` replaces the early 8.6 box by the merge scene, with one sentence; one sentence over each later box. | None seen. |
| **V033** Anatomy of a conflict | 18:20 | 80 MB | 12 % | PASS | The labels `MERGE_HEAD` and `ORIG_HEAD` arrived at 82 % of the 24 s paragraph that names them first (4:20 to 4:40 bare graph): `at_state_1=8` (4:31). | None seen. |
| **V034** Resolution workflow | 19:50 | 87 MB | 30 % | PASS | Nothing changed. | Final-pass item: the terminal title `labs/run ch08/pre-merge-checks` on the `restore --ours` card in the restore-sides lab (10:10; library #5). Second-parent commit drawn on the HEAD box border (4:04, 18:56; batch 2 #6). |
| **V035** Conflict types | 17:44 | 80 MB | 30 % | PASS | Nothing changed. | None seen. |
| **V036** Controlling the result | 16:09 | 69 MB | 37 % | PASS | Nothing changed. | None seen. |
| **V037** Clean for Git, wrong for humans | 18:52 | 78 MB | 29 % | PASS; warn C2 | **Built for the first time** (it had no MP4). Inspected in full (44 frames). | Final-pass item: stale terminal title `labs/run ch08/clean-but-wrong` over `git log -1 -p fc83756` (8:48; library #5). The DIAGRAM shows "M FAIL" and the root-cause box 14 s before "predict the result of the check" (6:24 to 6:42); the same story is told in CONCEPT before, so it is recall. Pace warning: section 7. Fix-list "2048." checked in the subtitles ("max_tokens 2048, was"). |
| **V038** What a remote is, clone | 19:07 | 81 MB | 26 % | PASS | Nothing changed. | None seen. |
| **V039** git fetch | 14:42 | 60 MB | 25 % | PASS | Nothing changed. Last frame of every scene looked at (fix-list). | None seen. |
| **V040** Upstreams, push.default, pull | 17:39 | 77 MB | 28 % | PASS | Nothing changed. | Part 3 prediction held over the previous table, which does not answer it (8:23). |
| **V041** git push | 17:43 | 76 MB | 29 % | PASS | Nothing changed. Fix-list `yours`: the commit is labelled "your commit" (5:54, 7:42). | The key-point code chip `git push <remote> --delete <branch>` runs off the right edge (9:04; library #6). |
| **V042** Forcing a push, the lease | 17:00 | 76 MB | 32 % | PASS | The first root-cause box of 12.8 flashed 2.5 s under "Step 6" and was never read (8:32): one sentence from its cells. | The DIAGRAM's six-row timeline is turned into a two-row table whose cells merge rows (6:29; library #7). A `walk` scene was tried (look `b12-v042`): its cells were cut short, so it was not used. |
| **V043** More than one remote, pruning | 17:18 | 74 MB | 32 % | PASS | Final-pass item: the GITHUB badge from "Layer label: GitHub" stayed on "Part 2", "Part 3" and "Part 4: stale refs" (plain Git). `end` before Part 2: the badge is now only on the fork paragraph (9:47 checked). | The "Part 2: the triangle" card is 1.7 s with an empty body (6:33). |
| **V044** Refspecs, transports, diagnoses | 17:31 | 77 MB | 23 % | PASS | Nothing changed. | **The refspec table shows `*` pairs as italics with a stray backslash**: "+refs/heads/\:refs/remotes/origin/\" (3:05 to 3:30; library #8). The fence may not be edited. |
| **V045** Gate briefing: branching | 9:56 | 38 MB | 33 % | PASS | Nothing changed. | The callout of the direction 'The "How a gate is taken" steps from assessments/README.md' splits around the quote (6:13; library #1). |
| **V046** The undo map, restore | 14:22 | 58 MB | 33 % | PASS | Nothing changed. | None seen. |
| **V047** git reset | 19:33 | 85 MB | 26 % | PASS | Interview Q171: the answer (the reset table scene) started 2 s after the question, under "Answer out loud, and draw the table". That sentence is now read over the question card, followed by a second 4.5 s pause, then the scene (17:37 to 17:46). No word changed. | None seen. |
| **V048** git revert | 13:53 | 59 MB | 35 % | PASS | Interview Q180: same pattern as V047, same fix (12:09). `revert-sequence` 01 and 02 stood 11 s silent (8:20): the first sentence of the next paragraph moved after 01 (no word changed). | `02-sequencer-state` page 1 3 s silent (8:29; library #4). Scene title in capitals (batch 2 #8). |
| **V049** Reverting a merge | 15:36 | 67 MB | 33 % | PASS | Interview Q182: same fix (13:55). | Code chip fills the key-point line, full stop alone below (8:49). |
| **V050** clean and stash | 16:23 | 67 MB | 30 % | PASS | Interview Q177: same fix (14:37). | Final-pass item: stale terminal title `labs/run ch11/clean` on the stash card (7:25; library #5). |
| **V051** Table, decision tree, scenarios | 13:28 | 58 MB | 27 % | PASS | Nothing changed. | Table page 1 3 s silent (1:54). |
| **V052** What a rebase is | 15:23 | 67 MB | 35 % | PASS | Nothing changed. | None seen. |
| **V053** Rebase internals | 14:56 | 66 MB | 29 % | PASS | Nothing changed. | None seen. |
| **V054** upstream, onto, keep-base, root | 15:36 | 67 MB | 32 % | PASS | Nothing changed. | None seen. |
| **V055** Interactive rebase | 15:47 | 69 MB | 26 % | PASS | Nothing changed. | Six todo-list transcripts have a 3 s silent page 1 (6:12 to 7:30; library #4). |
| **V056** Fixup, autosquash, update-refs | 20:06 | 89 MB | 33 % | PASS | Nothing changed. Last frame of every scene looked at. The recap replays now reach their final state (19:07 to 19:28; batch 2 #11 not seen). Hook `L2'` agrees with the narration. | None seen. |
| **V057** Conflicts during a rebase | 17:22 | 79 MB | 25 % | PASS | Nothing changed. | The exits table merges the rows `--continue`, `--skip`, `--abort` into one, their cells run together (3:04 to 3:18; library #7). |
| **V058** pull --rebase, range-diff | 13:56 | 61 MB | 25 % | PASS | Fix-list: the DIAGRAM drawing printed the three range-diff markers 80 s before "write one marker for each of the three commits". `step: series.state-1` now replaces the drawing with the old/new series graph without markers (5:17); the sentence "Only the middle line says that something changed." removed. The markers arrive with the answer after the pause. | The MENTAL MODEL quote stands 5 s in silence (4:16). |
| **V059** Rebasing a shared branch | 16:55 | 75 MB | 35 % | PASS | Nothing changed. | None seen. |
| **V060** Publishing a rebased branch | 16:18 | 75 MB | 28 % | PASS | Nothing changed. | Fix-list, **left**: the DIAGRAM graph shows tree `273096f` under both final commits (5:10 to 5:25), 4 min before "are the two final trees equal?" (9:23). The narration there says "keep it in mind for the demo"; nothing shows it during the quiz. It cannot be masked in the tag: `tree:` lines of a later state are drawn from the first state on (batch 2 #12). |
| **V061** What cherry-pick does | 16:27 | 71 MB | 26 % | PASS | Nothing changed. | None seen. |
| **V062** CHERRY_PICK_HEAD, sequencer | 17:07 | 77 MB | 26 % | PASS | Nothing changed. | Exits table rows merged (3:36; library #7). The quiz "HEAD detached or on the branch?" (6:57) can be answered from the DIAGRAM drawing 50 s earlier (recall). |
| **V063** Backports, duplicates | 15:50 | 68 MB | 29 % | PASS | Nothing changed. | `07-twice-in-history` types 3.8 s in silence and shows both lines 0.5 s (9:22). |
| **V064** Naming commits and ranges | 16:47 | 74 MB | 27 % | PASS | Fix-list: the DIAGRAM listed both ranges' commit sets and the diff endpoints 3 min before "shade main..feat/report" and "three dots, shade first". `step: plain.state-1` now replaces the drawing by the plain graph with only the merge base marked, and its sentence no longer gives the answers ("Keep it in mind for the demo."); both shading tasks are asked over the plain graph (8:12 to 8:42). | None seen. |
| **V065** Gate briefing: merge and rebase | 10:21 | 44 MB | 33 % | PASS | The quiz "in a stopped rebase, theirs is ..." was asked over the ours/base table (answer by elimination; batch 2). `end` before the quiz: it is a key point now (3:55). | The key point's big number reads "3 OPTIONS" and its headline holds only "option one, the upstream" (library #3); all three options are read. |
| **V066** Reading a diff | 18:01 | 78 MB | 27 % | PASS | Nothing changed. | `cmd_setup=` still not drawn in the three-boxes scene (12:48; batch 2 #13). Algorithm transcripts page 1 3 s silent (11:26, 11:38). |

### Imperfections that apply to several videos

1. **Drawings and boxes held in silence** (the "all ranges" fix-list item): 13 places, in V010 (2), V011, V012, V019, V027, V028 (11 pages), V031, V032 (4), V042, V048: each now has a sentence made of the drawing's or table's own cells, or a scene takes its place. Left: 3 s page holds of paged transcripts (library #4) and the V058 quote.
2. **Answers on screen before their question**: V017 (transcript comment), V031 and V032 (root-cause boxes before the demo), V058 and V064 (DIAGRAM), V065 (table): fixed. V060: left (library). Recall of an earlier picture by design: V010, V015, V035, V036, V037, V053, V059, V062.
3. **Interview answer pictures right after the question**: V047 to V050 played the answer scene 2 s after the question. Now the question card holds through two pauses. All other interview sections hold only the question card.
4. **Stale terminal titles** (V034, V037, V050) and the **V043 badge**: badge fixed; titles left (library #5).
5. **Explainer share**: 3 % (V028) to 37 % (V036). V010 to V033 mostly run 3 to 25 %: transcripts and tables carry them, as in batch 1.

## 3. Answers and causes (H3, H4)

| Video | Question | What the screen shows before it |
|---|---|---|
| V017 | "What does `git commit src/retriever.py` record?" (12:18) | Before: the previous transcript's comment line with the answer. Now: the question card only. |
| V031 | "Which temperature does each base give?" (10:46) | Before: root-cause box 8.5 at 8:14. Now: the criss-cross graph only. |
| V032 | `-X ignore-space-change` prediction (10:20) | Before: root-cause box 8.6 at 8:35. Now: the merge scene. |
| V058 | "Write one marker for each commit" (6:32) | Before: the drawing with the markers at 5:24. Now: the series graph without markers; the command only during the pause. |
| V060 | "Are the two final trees equal?" (9:23) | Tree `273096f` under both tips at 5:10 to 5:25 (left, library). During the pause: the rebase transcript. |
| V064 | Two shading tasks (8:12, 8:39) | Before: the drawing with both commit sets at 5:22. Now: the plain graph. |
| V065 | "theirs is ..." (4:05) | Before: the ours/base table. Now: a key point. |
| V047 to V050 | Interview questions | Before: the answer scene 2 s after the question. Now: the question card through both pauses. |
| All others | every pause and every interview question | Frames of every pause looked at: no answer on screen during a pause. |

No video in this range is an incident or drill video (H4 does not apply).

## 4. Fix-list and final-pass items

| Item | Outcome |
|---|---|
| V011 must be voiced again (a clip lost its mark) | **Closed**: rebuilt, C2 PASS. |
| V037 failed to build in the main run | **Closed**: built for the first time, QC PASS (one pace warning, section 7). |
| V058, V060, V064: answer in the DIAGRAM minutes before a prediction | **V058 and V064 closed** (section 3). **V060 open**: library #12 draws the `tree:` lines from the first state on. |
| V034, V037, V050 stale terminal titles | **Open**: library #5. Changing it would mean changing a `[TERMINAL]` direction. |
| V043 GitHub badge on a plain-Git slide | **Closed**: `end` before Part 2. |
| V041 placeholder `yours` | **Closed** (batch 2); checked again. |
| V037 "2048." | **Closed**; checked in the `.srt`. |
| V039 to V044, V056 to V066: last frame of each scene | **Done** for every scene of these videos. |
| V056 hook `L2'` | Checked: agrees with the narration. |
| All ranges: no diagram held in silence | **Closed** for drawings and boxes (section 2); 3 s page holds left (library #4). |
| All ranges: contraction passes, spot-check subtitles | Done by scan (no `**`, backtick, bracket tag or director note in any `.srt`); placeholders such as `<path>` appear as in the commands. |
| All ranges: one wording per term | **Open** (final pass, glossary). |

## 5. Other things corrected

- After each edit `python3 tools/inject.py --check` reported 0 problems for the script. `python3 tools/check_course.py` reports 0 problems at the end. (At the start it reported 6, all in `QC-SUMMARY.md` rows of V020 and V022; those rows passed after the final pass rebuilt them.)
- Narration growth (paragraph words): V010 2.5 %, V032 2.5 %, V028 1.8 %, V027 1.8 %, V019 1.7 %, V012 1.6 %, V011 1.3 %, V031 1.3 %, V042 1.2 %; V058 −0.4 %, V064 −0.2 %; V016, V017, V033, V043, V047, V048, V049, V050, V065 unchanged in count. No fact was added: every new sentence is made of the cells of the table, box or drawing on screen, or of the same paragraph.
- Changed: `[ANIMATION]`/`[PAUSE]` lines (V017 one `cards` tag; V031 one `step: grow`; V032 one `step: merge`; V033 `at_state_1=8`; V043, V028, V065 one `end` each; V058 one `step: series.state-1`; V064 one `step: plain.state-1`; V047 to V050 one `[PAUSE]` each), narration sentences named in section 2, and paragraph splits or moves. No snippet, table, heading or on-screen direction was touched. Nothing in `tools/` was edited.
- Every edited script was storyboarded in a scratch sandbox first: 0 warnings, 0 hints. To keep the final pass from failing a script that had changed under a built video, each edit was kept outside `video/scripts/` until its build started and was copied in by the queue. The scripts as they were before this pass: `video/production/.cache/inspect-b12/orig/`.

## 6. What was verified by looking, and what was not

Verified in frames of the finished videos: every item in the "What was fixed" column, in the rebuilt MP4; that no quiz, prediction, try-it or interview question is asked over, or followed within its pause by, a picture that shows its answer, at the sampled moments (V060 is the exception listed); the absence of overlapping or cut text and of literal underscores at the sampled moments, except where listed; that every risk label seen stands with its command.

Not verified: frames between the samples; the unchanged parts of a rebuilt video after its rebuild; the audio; the subtitles beyond the scans and the QC tool's checks; checklist items A13, C6, C7, E9 (need ears), F9, F10, G4, G5 and I8 to I10 (player, chapter clicks, thumbnails, upload).

## 7. The sound (not listened to)

Nobody listened to any of the 54 videos. What could be established without ears:

- `make.sh qc V010-V066`: all PASS. Loudness, peak, clipping, silence and the pace of every beat are inside the tool's bounds or accepted under the three-identical-takes rule; every clip has its verification mark.
- **Clips accepted under the three-identical-takes rule, to be listened to once:**

| Video | Time | Sentence | Measured |
|---|---|---|---|
| V037 | 0:36 | "None of the three needs a bug in Git. Each follows from what a merge is. This video answers the first two and shows you the mechanism of the third. Keep count." (one part of this beat was accepted under the rule) | 3.48 words/s, 12.9 letters/s |

- **Places worth one listen** although the tool does not flag them (new sentences of this pass, spoken for the first time):
  - **V028, 4:31 to 6:57**: the per-page sentences with setting names (`user.name`, `init.defaultBranch`, `pull.ff=only`, `push.autoSetupRemote`, `rebase.updateRefs`, `diff.colorMoved`, `core.autocrlf`, `core.excludesFile`, `commit.gpgSign`).
  - **V012, 7:59**: "`git rm --cached`" and "`git add .`" at the end of a sentence.
  - **V010, 6:54**: the IDs `cf6a5b3`, `e460212` and "retries: 1 becomes 3".
  - **V032, 10:29 and 11:41**: "-X ours" in the new sentence.
  - **V011, 7:01**: the clip re-voiced for C2, "Two pictures now. The textbook's analogy for the working tree ...".
- The voice builds: 21 builds, each at the first attempt, while the final pass voiced V020, V022, V025 and V070 under the same voice lock.
- The text given to the voice was scanned for presenter notes: none found. Every "Draw ...", "On screen, ..." and "Replay the commits ..." in the range is addressed to the viewer or describes the picture.

## 8. Library defects and limits found (nothing in `tools/` was edited)

| # | Where seen | Defect | Workaround used |
|---|---|---|---|
| 1 | V018 5:08, V029 2:12, V045 6:13 | A quoted `[ON SCREEN]` direction keeps its trailing words: `"Unverified", as a callout.` draws ", as a callout." under the quote; a direction naming a table outside the textbook (`assessments/README.md`) draws its own words instead of the table. | none (directions may not be changed) |
| 2 | V029 7:24 | A `[TERMINAL]` direction that also carries `On screen: "..."` is drawn as a callout labelled with the caption-bar path. | none |
| 3 | V028 17:27, V065 3:55 | Key point after a short lead sentence: a large empty card for 31 s; "3 OPTIONS" with only the first option in the headline. | none |
| 4 | V019, V030, V048, V051, V055, V066 | Paged transcripts and tables: a page with no paragraph of its own stands 3 s in silence; narrow cells wrap inside a word ("unchange / d"). Same as batch 6 #3, #4. | paragraph splits where possible (V011, V016, V028, V031) |
| 5 | V034 10:10, V037 8:48, V050 7:25 | A single-command card takes its title from the first `labs/run` of the `[TERMINAL]` direction, not from the lab being run (batch 2 #1). | none |
| 6 | V041 9:04, V049 8:49 | A long code chip in a key-point headline is not wrapped: it runs off the right edge or leaves the full stop alone on the next line. | none |
| 7 | V042 6:29, V057 3:04, V062 3:36 | A `text` fence drawn as a table merges several rows into one when their lines are adjacent (exits tables; the six-row lease timeline). Batch 6 #1. A `walk` scene cuts long cells short (look `b12-v042`). | none |
| 8 | V044 3:05 | Asterisks in a `text` fence drawn as a table are read as Markdown emphasis: `+refs/heads/*:refs/remotes/origin/*` shows as italics with a stray backslash. | none |
| 9 | V060 5:10 | `tree:` lines of a later `+` state are drawn from the first state on (batch 2 #12), so an answer cannot be held back. | none |
| 10 | V031 | A `[DIAGRAM] Show the root-cause box.` direction after the demo draws nothing when the box was replaced earlier. | a sentence over a key point |

## 9. Verification at the end

- `make.sh qc V010-V066` at about 11:50: all PASS, 0 failed. For every video of the range the script SHA-1 in the storyboard and in `VNNN.build.json` equals the script on disk, and the beat count equals the number of beat starts.
- Storyboards: no warning and no hint for any of the 54. `python3 tools/check_course.py`: 0 problems.
- Rebuilds ran one at a time from a detached queue started with `setopt NO_BG_NICE`, 09:39 to 11:47. `--look` renders one at a time (prefix `b12-`, two renders); look folders and all frames are deleted. Logs: `video/production/.cache/inspect-b12/rebuild.log`; working notes: `video/production/.cache/inspect-b12-progress.md`.
- **Disk**: 11 to 13 GB free until 11:20, then falling while the final pass ran (9.8 GB at 11:31, 7.1 GB at 11:40, **3.2 GB at 11:47**). My last build had already started at 7 GB; the queue was stopped after it. The disk watchdog has paused `final.sh` (state T) before its closing `qc all`; the space is not taken by my folders (2.5 MB left). Someone should look at the disk before the next build.
- Times in this report are from the final builds.
- No `git` command was run in the course directory, nothing was run against GitHub, no video outside V010 to V066 was touched (V020, V022, V025 excluded), and nothing in `tools/` was edited.

## 10. Ready to upload?

V010 to V066, without V020, V022 and V025, are ready from the tool's and the eyes' side: QC PASS for all 54, frames inspected, every fix re-inspected in the new MP4, no answer on screen before or during its question except V060 (a library limit; the answer is shown 4 minutes earlier and not during the quiz). The library defects of section 8 remain visible in V018, V029, V034, V037, V042, V044, V050, V057 and V062; none of them shows a wrong fact, but V018 (", as a callout.") and V044 (the refspec table's asterisks) are visible mistakes on screen. Before upload, a person should do the "ears" items, at least the V037 clip at 0:36 and the places listed in section 7, and should check the free disk space (3.2 GB at the end).
