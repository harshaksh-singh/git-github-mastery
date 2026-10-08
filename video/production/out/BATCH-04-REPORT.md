# Batch 4 (V112 to V133): finishing report

Written 2026-10-08 by the finishing inspector of V112 to V133. Voice: the macOS voice Tara at 165 words per minute, no paid service. Every video carries the animation layer and was voiced with the repaired voice step. The form follows `BATCH-03B-REPORT.md`.

## 1. Result

- **22 of 22 videos built, 22 of 22 PASS from the QC tool** (`make.sh qc V112-V133`, run at 19:35 after the last build): 1920x1080, 30/1 fps, H.264 and AAC, picture and sound equal within 0.009 s, built from the script as it is now, storyboards with no warning and no notice. Warnings: subtitle line length (E5, all 22) and reading speed (E6, 17). **No pace warning** (no clip accepted under the three-identical-takes rule in this range).
- Total length 6 h 19 min, 1.65 GB. Files: `video/production/out/VNNN.mp4` with `.srt`, `.chapters.txt`, `.build.json`; QC reports in `video/production/out/qc/`.
- **At the start** 20 passed, V133 failed QC (C3: the narration "n/a" reached the voice as a raw symbol), and V127 had no MP4 (its voice build had failed on "Read sections 17.15, 17.17 and 17.18 of Chapter 17." before the rule fix). V112 already passed C2 in its build of 13:41 (it had been voiced again by the main run).
- **18 videos were rebuilt** (storyboard, slides, animate niced; voice at normal priority; QC niced; one at a time from a detached queue): V112, V113, V115, V116, V117, V118, V119, V120, V121, V122, V123, V124, V125, V127, V128, V129, V130, V133. Each was built once, except V119 (twice: the re-inspection of its first build found a new defect, section 6, item 1) and V127 (a voice-only build at 17:33 to have an MP4 to inspect, which built the formerly failing sentence at the first attempt, then a slipped voice-only build and a full build after its script fix). Every voice build succeeded at the first attempt; no sentence was refused.
- **Not rebuilt:** V114, V126, V131, V132 (builds of the main voice run, 13:51 to 17:09 today).
- **How they were inspected.** From frames of the finished MP4s with the script and the storyboard open: the last moment of every explainer-scene beat, the middle of each long scene and long beat, every drawing, every silent hold and prediction pause, and six frames spread over the length: 27 to 42 frames per video, 742 in all, looked at as 132 contact sheets of six half-size frames, with full-resolution crops where a sheet left a doubt (about 20). After each rebuild the changed places were looked at again in the new MP4 (2 to 8 frames each, 70 in all); the unchanged parts of a rebuilt video were not looked at a second time. Proposed scene changes were checked with `--look` first (prefix `b4-`, one at a time, 11 renders).
- **Not done: nobody listened.** No audio was heard at any point. Section 7 lists what was done for the sound.

"Explainer scenes" is the share of the running time during which a library scene or an animated commit graph is on screen. "QC tool" is the result of `make.sh qc VNNN`.

## 2. Per video

| Video | Length | Size | Explainer scenes | QC tool | What was fixed | Still imperfect |
|---|---|---|---|---|---|---|
| **V112** Living in a sparse checkout, the sparse index | 14:45 | 61 MB | 27 % | PASS; warn E5,E6 | Interview: the answer table ("Narrowing a cone", three kinds of file) came on screen 2 s after the question, under "Answer out loud"; the question card now stays (13:27, 13:42). | A key point at 1:13 is a tall, mostly empty panel (library). |
| **V113** Partial clone + sparse checkout, scalar, monorepo CI and releases | 17:40 | 74 MB | 25 % | PASS; warn E5 | Interview: the shallow-clone picture (the answer) stood under "Answer out loud"; removed (16:08, 16:25). Fix list: HEAD on `main` in `orbit` and the "19 more" / "27 more" of the tags graph verified in the sandbox (section 3). | The scalar configuration list is read setting by setting with every dot and equals sign (4:17 to 4:30, section 7). |
| **V114** Gate briefing: Internals | 11:10 | 45 MB | 25 % | PASS; warn E5 | Nothing needed changing. | None seen. |
| **V115** Git data and GitHub objects, accounts, roles, settings | 17:29 | 75 MB | 30 % | PASS; warn E5,E6 | Interview: the 15.2 table (the answer) under "Answer out loud"; removed (16:04, 16:17). | Two pages of the 15.2 table stand 3 s each in silence (3:03). A key point at 10:12 is a tall empty panel (library). |
| **V116** Forks and the fork network | 13:50 | 56 MB | 20 % | PASS; warn E5 | Interview: the "fork deleted, object stays" picture under "Answer out loud"; removed (12:41, 12:53). | Key points at 5:46 and 10:23 are tall empty panels (library). Explainer share 20 %. |
| **V117** Issues, Projects, Discussions, Packages, health files | 20:10 | 89 MB | 24 % | PASS; warn E5,E6 | Interview: the three-causes decision path under "Answer out loud"; removed (18:40, 18:54). The presenter note "Now show the files taking effect after the push" (read aloud) is now "Now watch the files take effect after the push" (15:48). Fix list: chain `bf7889c` - `c7182c9` - `39c4105` on `main` verified (section 3). | "Point at `labels: ["bug"]` ..." (script line 257) is read as an instruction to the viewer; left. |
| **V118** Authentication vs authorization, how Git asks for a credential | 17:12 | 78 MB | 23 % | PASS; warn E5,E6 | Interview: the full get/store/erase protocol picture under "Answer out loud"; removed (15:43, 15:56). | None seen. |
| **V119** Tokens, prefixes, and why a token never goes into a URL | 13:50 | 61 MB | 30 % | PASS; warn E5,E6 | Final-pass item: the root-cause box (which says that `git remote set-url` refuses) was on screen at 8:02, 67 s before the prediction "Does it work?". The box (direction and fence unchanged) now stands after the reveal (9:33) with one sentence ("Read the root-cause line ..."); the DIAGRAM section opens with the leak picture. The leak picture showed three empty boxes for most of a 22 s paragraph; its first row now arrives at 30 % (5:54). Interview: the leak picture under "Answer out loud"; removed (12:37). | None seen. |
| **V120** SSH key pairs, agent, config, host keys | 19:53 | 83 MB | 24 % | PASS; warn E5,E6 | Interview: the host-key decision path under "Answer out loud"; removed (18:23, 18:37). Fix list: fingerprints already in the two-line long-value form, seen (7:41, 14:26). | None seen. |
| **V121** Two identities, machine credentials, SSO, the announced SSH changes | 18:08 | 83 MB | 21 % | PASS; warn E5 | Interview: the URL-routing picture under "Answer out loud"; removed (16:18, 16:33). | Fix list: the 16.16 table (8:08, 16 s) highlights no row and states the changes in the textbook's indicative wording; each dated paragraph says "as announced", and the walk scene after it repeats the three rows under "Announced, not observed". Left (section 3). Key point at 1:30 tall and empty (library). |
| **V122** Diagnosing authentication failures | 16:38 | 78 MB | 30 % | PASS; warn E5,E6 | The two root-cause boxes (8.2 s of silence each at 10:49 and 11:24) are now read, one sentence each from the box (10:55, 11:31). Narration +2.7 %. | None seen. |
| **V123** What GitHub creates when a pull request opens | 17:28 | 77 MB | 20 % | PASS; warn E5,E6 | Refs graph (six appearances): the edge from `16d4788` to the test merge ran through the ID `135aad1`, another edge touched `9a383e5`; the two oldest commits are now "older" and the graph is wider and flatter: every ID readable (2:58, 4:22, 4:53, 16:21). Recap: the production caption "The job recorded the test merge ..." stood over the recap sentence; removed. | A count key point at 8:10 reads "3 / COMMITS AS" (library chooses the noun). Explainer share 20 %. |
| **V124** Pull request lifecycle, stale approvals, mergeability, conflicts | 17:44 | 77 MB | 27 % | PASS; warn E5,E6 | Lifecycle diagram: the labels "mark ready", "review submitted" and "convert to draft" lay over the state boxes; with `ready` one row lower the boxes are clear (2:33, 3:05). Two `say:` captions on `pr` scenes were drawn across the stage circles 1 to 5 (5:26, 5:59); removed (the narration says the same). | 13:17: the walkthrough direction is drawn as the textbook's "Outdated advice" box of 17.4 (draft pull requests and a paid plan, "Since 1 May 2025"): text the script does not state, under the walkthrough paragraph, not read (section 6, item 2). |
| **V125** Why a pull request shows unexpected commits | 17:23 | 78 MB | 18 % | PASS; warn E5,E6 | The root-cause box (9.2 s of silence, 8:00) is read (8:04). | Explainer share 18 %. The walkthrough direction at 12:28 is a card of its own wording with the page title in large quotes (only the script's words). |
| **V126** Indirect merges and stacked pull requests | 16:01 | 65 MB | 29 % | PASS; warn E5,E6 | Nothing changed. Fix list: the merge commit `M` kept (section 3). | In the transplant state of the stack graph the `main` chip sits on the dashed edge under `77fc160` (7:02, 9:08, 11:21, 13:41). |
| **V127** The fork workflow end to end | 16:35 | 71 MB | 21 % | PASS; warn E5,E6 | Final-pass item: built (at 17:33 at the first attempt, the sentence of section numbers included). Clone graph: during "deleted after the merge, locally and in the fork" the labels `fix/empty-subject` and `origin/fix/empty-subject` never left (11:26 to 11:31, four frames); they now leave (section 6, item 3). | The label `a-new-branch` in the production graph (13:30) is the editor's rendering of "a new branch" (the script names none). |
| **V128** The three merge methods | 16:28 | 80 MB | 15 % | PASS; warn E5,E6 | Hook graph: the label `the-pull-request-ref` (not in the script) is now `refs/pull/N/head` (0:43). The state table (70 words, 5 s of silence at 11:22) has one paragraph made of its own sentences (11:29). | Fix list: the ASCII comparison is kept (section 3). Explainer share 15 %. |
| **V129** What the merge method means later, auto-merge, merge queue | 19:59 | 92 MB | 32 % | PASS; warn E5,E6 | The root-cause box (8.2 s of silence, 11:04) is read (11:07). | Merge-queue graph (8:21 to 8:52): in the states "temporary" and "fails" the label `gh-readonly-queue/main/pr-2` covers commit `0569767`, and edges cross `9a383e5` and `2b79f02`. Three alternative layouts were rendered and were worse (section 6, item 5). |
| **V130** A Git tag versus a GitHub Release | 15:15 | 62 MB | 27 % | PASS; warn E5 | The root-cause box (7.8 s of silence, 8:21) is read (8:28). The quiz "gh release delete: what happens to the tag?" came right after the narration had read the answer from the state table ("the tag stays, unless --cleanup-tag is given"); it is now worded as recall: "Quick quiz on that last row, from memory now that the table is gone." | The answer is still spoken 10 s before the quiz; only the framing changed. Two state-table pages stand 3 s each in silence (5:37, 6:06). |
| **V131** What a rule is, rulesets, layering, bypass | 19:45 | 82 MB | 24 % | PASS; warn E5,E6 | Nothing needed changing. | The diagram section (10:22) keeps the mental-model caption "Several sheets of conditions ..." (it does not contradict). |
| **V132** Required reviews, status checks and their traps | 20:32 | 92 MB | 27 % | PASS; warn E5,E6 | Nothing changed. Fix list: placeholders `A`, `M` kept (section 3). | `merge` scene (8:20, 15:05): the edge from `A` to `M` runs through the ID `16d4788` (library). Two walk scenes show only their header during their first paragraph (3:59, 9:31). Two table pages stand 3 s each in silence (3:30, 7:45). |
| **V133** Tag, push and organization rulesets, classic protection, plan gates | 20:53 | 93 MB | 29 % | PASS; warn E5,E6 | QC C3 (failed): 'The cells marked "n/a"' reached the voice as a raw slash; now "The cells marked with the letters n and a" (final-pass item 3, closed by rewording). Fix list: placeholders `A-B` kept (section 3). | None seen. |

### Imperfections that apply to several videos

- **Answer pictures under the interview question** (V112, V113, V115 to V121): every one of these nine put a `step:` back on screen 2 s after the CTO question, the picture being the answer the viewer is asked to give out loud (the defect 3B fixed in V111). All nine removed; V122 to V133 had none.
- **Root-cause boxes held in silence** (V122 twice, V125, V129, V130): each now has one sentence from its own box. Tables still held in silence for 3 s per page: V115, V130, V132 (two pages each).
- **Unquoted on-screen directions that a section number links to a textbook box** (V124, and V119 in its first rebuild): the slide shows the textbook's box, not the script's words (section 6, item 2).
- **Explainer share**: 15 to 32 %; V128 (15 %), V125 (18 %), V116 and V123 (20 %) are below the aim of a quarter.
- **Edges close to IDs and labels over commits**: fixed in V123; left in V129 (label over a commit), V132 (edge through an ID), V126 (chip on an edge).
- **Terminals type before they are spoken about** (the pipeline's normal behaviour): silent terminal holds of 6 to 8 s in V114 (6:52), V116 (8:56), V123 (9:53).

## 3. Fix-list and final-pass items

| Item | Outcome |
|---|---|
| V112: a clip lost its verified mark and must be voiced again | **Closed before this pass.** The MP4 of 13:41 passed C2; rebuilt again here for the interview fix, QC PASS. |
| V127 failed its voice build on a sentence of section numbers | **Closed.** Built at 17:33 after the rule fix (17:24 file time), the sentence voiced at the first attempt; rebuilt in full after the script fix, QC PASS. |
| V119: root-cause box shows the refusal before the prediction | **Closed** (section 2). Seen at 8:02 to 8:17 (no box) and 9:33 to 9:58 (box after the reveal). |
| V113: HEAD on `main` in `orbit` | **Closed.** Script line 312 prints `100bb99 (HEAD -> main, ...)`; the sandbox replay of `labs/run ch24/project-tags` gives the same. The graph's "19 more" and "27 more" also verified there: `git rev-list --count 52ee19b..f5915c9` = 20 and `f5915c9..100bb99` = 28. |
| V117: chain `bf7889c` → `c7182c9` → `39c4105`, branch `main` | **Closed.** Sandbox replay of `labs/run ch15/large-objects`: `39c4105 (HEAD -> main)`, parent `c7182c9`, parent `bf7889c`. |
| V120: hash cards cut to 8 characters | **Closed by the scene pass, seen.** Both fingerprints are drawn whole in the two-line form (6:58 to 7:41, 14:10 to 14:26). |
| V121: three dated paragraphs; does the 16.16 table still highlight the right row? | **Checked, left open in part.** The table no longer highlights any row (paragraphs start with words); it stands 16 s under the first dated paragraph. Every dated paragraph says "as announced", and the walk scene "Announced, not observed" carries the three rows. Putting the walk scene over the first paragraph would hold the table 3 s in silence (storyboard rule), so it was left. |
| V126 (`M`), V132, V133 (`A-B`): placeholder commits | **Kept, as the item allows.** V126: the transcript `08-indirect-merge` runs `git merge -q` and prints no ID for the merge. V132: no snippet prints the `origin/main` commit or the merge. V133: the transcripts print only the tag-object IDs `13ad80e` and `d68a79d` (drawn), no commit ID. |
| V128: replace the ASCII comparison if the three-methods scene matches it | **Kept.** `methods` was rendered side by side (`--look b4-v128b`): IDs 10.6 px and notes 12 px, the layout check complains; stacked in rows the narration's "on the left / in the middle / on the right" would be wrong, and the scene cannot show the bracketed originals that "stay on the old branch". The drawing (8:20) is readable and narrated. |
| Final pass item 3: C3 flags V133 "n/a" | **Closed** by rewording the narration (V133 PASS). |
| All ranges: no diagram held in silence | **Checked.** Every `[DIAGRAM]` drawing has narration. Root-cause boxes held in silence: five now have a sentence; none is left in this range. |
| All ranges: caveats read aloud, not only shown (V115 to V133) | **Checked from the scripts and the storyboards.** Every "documented", "unverified", "as announced" and "inference" statement in V115 to V133 is in narration paragraphs, key points or read callouts; spot-checked in the subtitles. The one caveat shown and not read is the textbook's "Outdated advice" box in V124 (not a script caveat; section 6, item 2). |
| All ranges: one wording per term | **Open** (final pass, with the glossary). |

## 4. Other things corrected

- After each edit `python3 tools/inject.py --check` reported 0 problems for the script, and `python3 tools/check_course.py` reports 0 problems at the end.
- Narration growth: V122 2.7 %, V130 1.7 %, V128 1.4 %, V125 0.7 %, V119 0.6 %, V129 0.4 %, V133 0.2 %; no fact was added: every new sentence is made of the words of a root-cause box, a state table or the same paragraph.
- Changed: `[ANIMATION]` lines; the narration sentences named in section 2; in V119 the root-cause box (its `[ON SCREEN]` direction and fence, content unchanged) was moved from the DIAGRAM section to after the reveal, as the final-pass item asks. No snippet, table, heading or other direction was touched. Nothing in `tools/` was edited.
- Every edited script was storyboarded in a scratch sandbox first (`VIDEO_WORK_DIR` in the scratchpad): 0 warnings, 0 notices.

## 5. What was verified by looking, and what was not

Verified in frames of the finished videos: every item in the "What was fixed" column; the absence of overlapping or cut text and of literal underscores in captions and labels at the sampled moments, except where listed as still imperfect; that no interview question is followed by its answer picture (all 22 looked at, nine fixed); that no quiz is asked over a picture that shows its answer (every pause that stands over a scene, a table or terminal output was judged at the sampled moments; V130 found and reworded, V119 found and fixed); that scene captions fit the paragraph being read at the sampled moments (two stale captions found: V123 fixed, V131 left).

Not verified: frames between the samples; the unchanged parts of a rebuilt video after its rebuild; the audio; the subtitles beyond the scans of section 7 and the QC tool's checks; checklist items A13, C6, C7, E9 (need ears), F9, F10, G4, G5 and I8 to I10 (player, chapter clicks, thumbnails, upload).

## 6. Library defects and limits found (nothing in `tools/` was edited)

| # | Where seen | Defect | Workaround used |
|---|---|---|---|
| 1 | V119 (first rebuild, 8:02) | A `step:` tag between an unquoted `[ON SCREEN]` direction and its fence replaces the fence but leaves the direction as a callout, which then shows a textbook box of the section the direction names (here 16.7's "Outdated advice": "The Phase 0 report found a 2024 workshop video ..."), 50 words for 3 s. No warning. | box moved after the reveal (fix-list item) |
| 2 | V124 13:17 | An unquoted walkthrough direction that cites "sections 17.4 and 17.5" is drawn as the textbook's "Outdated advice" box of 17.4: text the script does not state, labelled "Outdated advice", under the walkthrough narration, not read. A `step:` tag after the direction turns it into a 5 s silent hold instead. No warning. | none; open |
| 3 | V127 11:26 | In a `graph`, a full state (not `+`) that leaves out two labels does not remove them in the played clip, although the still of that state has them removed; `--look` shows the same (labels present in the last frame). `+ drop:a,b` works. | `+ drop:` |
| 4 | V124 5:26, 5:59 | `say:` on a `pr` scene draws the caption across the stage row (circles 1 to 5); the scene has no caption line. No warning. | tags removed |
| 5 | V129 8:21 to 8:52 | `queue` graph with 27-character labels: the label of one entry covers the next commit; `--look` reports "layout check: clean". A one-row (`^`) layout keeps everything visible only at 14.7 px text and hides the FAIL mark under a label; a staircase zooms out to 14 px. | none; original kept |
| 6 | V124 2:33 (before the fix) | `lifecycle`/`decide` with a straight row of states: edge labels lie on the state boxes; `--look` reports "clean". `grid=` with a staggered row fixes it. | `grid=` |
| 7 | V132 8:20, 15:05 | `merge` scene: the edge from the base-side commit to the merge commit runs through the ID of the last branch commit (`16d4788`). | none |
| 8 | V123 8:10 | Count key point picks the noun after the number: "3 / COMMITS AS". | none |
| 9 | V112 1:13, V115 10:12, V116 5:46 and 10:23, V121 1:30 | Key points in the card layout: one line at the top of a tall empty panel (3B item 8). | none |
| 10 | V128 (look `b4-v128b`) | `methods` with three panels side by side: IDs fall to 10.6 px. | ASCII drawing kept |

## 7. The sound (not listened to)

Nobody listened to any of the 22 videos. What could be established without ears:

- `make.sh qc V112-V133`: 22 PASS. Loudness, peak, clipping, silence and the pace of every beat are inside the tool's bounds; every voice clip has its verification mark.
- **Clips accepted under the three-identical-takes rule, to be listened to once: none.** No video of this range has a C1 or C2 warning.
- Places worth one listen although the tool does not flag them:
  - **V127, 16:14**: "Read sections 17.15, 17.17 and 17.18 of Chapter 17." (the sentence that failed before the rule fix; built at the first attempt at 17:33).
  - **V113, 4:17 to 4:30**: the scalar configuration list read as "commit Graph dot changed Paths equals true, core dot un-tracked Cache equals true, index dot version equals 4 ..." (long, symbol by symbol).
  - **V131, 13:30**: "qa slash star star slash star matches any number of slashes".
- The voice builds: 20 builds for 18 videos, each at the first attempt. The main voice run was working on V134 to V138 at the same time.
- **The text given to the voice** (`.cache/tts/VNNN.spoken.txt`, all 22) was scanned for symbol wording, contractions and presenter notes; every "it's" in the subtitles was read in its sentence (none wrong). Odd wordings that remain:

| Video | The voice is given | Remark |
|---|---|---|
| V119 | "ghp underscore", "github pat underscore", ... | token prefixes; consistent |
| V113 | "commit Graph dot changed Paths equals true, ..." | configuration keys spelled out; long |
| V118 | "GIT TRACE equals 1", "key equals value lines" | consistent |
| V130 | "with the caret, empty curly braces suffix" | `^{}`; as in V100 |
| V131 | "qa slash star star slash star", "tilde DEFAULT BRANCH" | patterns read symbol by symbol |
| V133 | "The cells marked with the letters n and a" | the reworded C3 sentence |
| V117 | "Point at labels: "bug" in square brackets ..." | the script addresses the viewer; left |

## 8. Verification at the end

- `make.sh qc V112-V133` at 19:35: 22 PASS, 0 failed. ffprobe and `VNNN.build.json` for all 22: section 1; the script hash in every storyboard equals the script on disk, and every MP4 is newer than its script.
- Storyboards: no warning and no notice for any of the 22. `python3 tools/check_course.py`: 0 problems.
- Rebuilds ran one at a time from a detached queue started with `setopt NO_BG_NICE` (storyboard, slides and animate under `nice -n 20`, voice at normal priority), 17:29 to 19:32. `--look` renders one at a time (prefix `b4-`); look folders and all frames are deleted. Log: `video/production/.cache/inspect-b4/rebuild.log`; working notes: `video/production/.cache/inspect-b4-progress.md`; the scripts as they were before this pass: `video/production/.cache/inspect-b4/orig/`.
- Times in this report are from the final builds.
- No `git` command was run in the course directory (two labs were replayed, and their repositories read, in a scratchpad sandbox outside it), nothing was run against GitHub, no video outside V112 to V133 was touched, and nothing in `tools/` was edited.
