# Batch 3B (V089 to V111): finishing report

Written 2026-10-08 by the finishing inspector of V089 to V111. Voice: the macOS voice Tara at 165 words per minute, no paid service. Every video carries the animation layer and was voiced with the repaired voice step. The form follows `BATCH-03A-REPORT.md`.

## 1. Result

- **23 of 23 videos built, 23 of 23 PASS from the QC tool** (`make.sh qc V089-V111`, run at 15:38 after the last build): 1920x1080, 30/1 fps, H.264 and AAC, picture and sound equal within 0.012 s, built from the script as it is now, storyboards with no warning and no notice. Warnings: subtitle line length (E5, all 23), reading speed (E6, 11), and one pace warning (V095, section 7).
- Total length 6 h 4 min, 1.60 GB. Files: `video/production/out/VNNN.mp4` with `.srt`, `.chapters.txt`, `.build.json`; QC reports in `video/production/out/qc/`.
- **At the start three failed QC** (V090, V093, V095: MP4s of 7 October, never voiced with the repaired step). **15 videos were rebuilt in this pass, each once**: V089, V090, V091, V092, V093, V094, V095, V096, V097, V100, V103, V104, V105, V108, V111. Eight were not rebuilt: V098, V099, V101, V102, V106, V107, V109, V110 (the builds of the main voice run of 8 October, 12:04 to 13:32; V109 and V110, named in the final-pass list, pass QC in those builds).
- **How they were inspected.** From frames of the finished MP4s with the script and the storyboard open: the last moment of every beat that shows an explainer scene, the middle of every long scene, every hand-drawn drawing, every silent hold and prediction pause, and six frames spread over the length: 21 to 41 frames per video, 729 in all, looked at as 130 contact sheets of six half-size frames, and at full size where a sheet left a doubt; 30 more frames at particular moments. After each rebuild the changed places were looked at again in the new MP4 (2 to 8 frames each, 60 in all); the unchanged parts of a rebuilt video were not looked at a second time.
- **Not done: nobody listened.** No audio was heard at any point. Whether a word is pronounced correctly is unknown. What was done for the sound is in section 7.

"Explainer scenes" is the share of the running time during which a library scene or an animated commit graph is on screen. "QC tool" is the result of `make.sh qc VNNN`.

## 2. Per video

| Video | Length | Size | Explainer scenes | QC tool | What was fixed | Still imperfect |
|---|---|---|---|---|---|---|
| **V089** Hooks: programs that Git runs at fixed points | 14:46 | 67 MB | 26 % | PASS; warn E5 | Amend graph: the label was cut in mid-slide over the ID `3f5eb96` (the step started 82 % into a 4.9 s paragraph); it now settles at 6:08. Rebase graph: two edges ran through the ID `0443504`; `6c7937a` is drawn above the line and the IDs are clear. | In the last state of the rebase graph one edge clips the first letters of the note "copy of 6c7937a". In the three group pictures the tick marks touch the group titles (library). |
| **V090** --no-verify, core.hooksPath, sharing hooks, hook security | 16:14 | 72 MB | 32 % | PASS; warn E5,E6 | Mental model: the caption "A clone brings the goods..." stood over the wrong picture (the four "fails open" cards); it now stands over the clone and archive picture (6:24). The caveat of the pre-commit framework segment ("described from its documentation, nothing in it was run") is now read. | The GitHub lower third (script line 443: no server-side hooks on github.com, the equivalents) is neither shown nor read (section 6, item 2). A transcript types 8 s in silence at 10:19. |
| **V091** Submodules: a gitlink, .gitmodules, and what a teammate receives | 14:49 | 67 MB | 28 % | PASS; warn E5,E6 | Mental model: the three recipe-book captions stood over the wrong picture (the transport decision tree) for a minute; they now stand over "Three things that should agree". The gitlink arrow and the last row of the clone picture arrive inside their short paragraphs (both were cut). The "Outdated advice" caveat is read over its card (5 s of silence before). "on the first slide" reworded to "from the opening". | The gitlink arrow runs behind the HEAD chip and the `main` chip. The seven-column state table breaks "unchange / d" and stands 5 s in silence (8:38). The prefix table stays on screen under the next two paragraphs and the quiz (it does not give the answer). |
| **V092** Submodules in motion | 14:52 | 67 MB | 25 % | PASS; warn E5,E6 | "Moving the pointer": three steps in 8 s, cut with the tag half-way over `origin/main`; now settled at 7:36. The root-cause box (7.5 s of silence) has its root-cause sentence read. | In the four-commit panel of the rollback picture the IDs are small (about 14 px). |
| **V093** Submodule failures | 17:30 | 81 MB | 25 % | PASS; warn E5,E6 | Built with the repaired voice (it had failed QC on peak level, clipping and six beats). The GitHub Actions caveat ("described from the action's documentation; nothing was captured") was neither shown nor read; it is now a key point with the badge and is read (12:16). | A transcript types 7 s in silence at 8:07. |
| **V094** Subtrees, and choosing | 14:59 | 67 MB | 20 % | PASS; warn E5 | Both subtree graphs: the merge edges ran through the IDs `bf78eb9` and `fb692e1`; wider columns, every ID readable. Fix list: the parent links agree with the script's own `git log --graph` transcripts (`01-add`, `04-pull`, `07-split`). The state table and the decision table (12 s of silence) each have one sentence. | The first two pages of the state table still stand 3 s each in silence; the second page of the decision table is under the next paragraph. Edges pass closely above `fb692e1`. Explainer share 20 %. |
| **V095** Git LFS: why it exists | 15:23 | 66 MB | 23 % | PASS; warn C1,C2,E5,E6 | Built with the repaired voice. One sentence had to be shortened by two words, because the voice step refused it in every take (section 6, item 1). | One clip to listen to (section 7). The seven-column state table stands 5 s in silence (10:57). A key point at 6:53 is a tall, mostly empty panel (library). |
| **V096** Git LFS day to day | 16:35 | 74 MB | 27 % | PASS; warn E5 | The GitHub Actions note ("Not run for the book", 60 words and a quotation, shown 5 s in silence) is read over its card (10:40). "Say this on screen now, before the first replay" (a presenter note that was read aloud) reworded. | The GitHub lower third at script line 192 shows only its badge; its text is not read. A transcript types 7 s in silence at 10:17. |
| **V097** git lfs migrate, LFS errors, limits and billing | 19:10 | 88 MB | 20 % | PASS; warn E5,E6 | The "Unverified" caveat about prices (a one-word card, 5 s of silence), the "Volatile script" caveat (a one-word card under other narration) and the GitHub caveat ("as read on 2 October 2026; limits and prices change") are now read while their cards are shown. Both migration graphs with wider columns (edges grazed `c96fc1c` and the `origin/main` chip). The root-cause sentence is spoken with its graph. Narration grew 3.0 %. | The root-cause box itself stands 8.9 s in silence at about 7:03. The volatile note of the export demo (script line 383) is neither shown nor read. The billing table's first page stands 3 s in silence. Explainer share 20 %. |
| **V098** Gate briefing: Recovery | 9:59 | 42 MB | 22 % | PASS; warn E5,E6 | Nothing needed changing. | Two card pictures sit low in the frame with the upper half empty (library layout). |
| **V099** The .git directory file by file | 17:24 | 74 MB | 19 % | PASS; warn E5 | Nothing changed. | The inventory table stands 12 s in silence (9:41, three pages), although its direction says "read the rows aloud". In the storage picture the arrow labels "hash" and "compress" touch. Explainer share 19 %. |
| **V100** The four object types in full | 17:29 | 78 MB | 27 % | PASS; warn E5 | History graph (four appearances): two edges ran through the first and last character of `b602c1f` and `0c2cf43`; the side commit is drawn above the line. | None seen. |
| **V101** git rev-parse | 13:13 | 56 MB | 24 % | PASS; warn E5 | Nothing needed changing. | The root-cause box stands 7.2 s in silence (9:06). |
| **V102** Packfiles, pack indexes and delta compression | 15:41 | 70 MB | 31 % | PASS; warn E5 | Nothing needed changing. | A transcript types 7.8 s in silence at 11:25. |
| **V103** Reachability, git fsck | 15:28 | 65 MB | 27 % | PASS; warn E5 | Two-dates picture: the caption covered the panel name "dated-2099"; it is now on the caption line above both panels (10:34). Fix list: the reflog-only style is in use. | None seen. |
| **V104** What makes a repository slow | 19:11 | 85 MB | 22 % | PASS; warn E5,E6 | The try-it "which packs will Git merge?" was asked over a box headed "24 is less than 2 x 24", the check it asks for; the heading now reads "the same rule, pair by pair". The state table of `git maintenance run` (45 words, shown for 2.4 s) is read. | None seen. |
| **V105** Refs in depth | 17:45 | 79 MB | 27 % | PASS; warn E5 | Recap graph: cut in mid-slide with the `origin/main` chip over the ID `0c2cf43`; now settled. The root-cause box (7.5 s of silence) has its root-cause sentence. Fix list: parent links agree with the transcript in V100. | None seen. |
| **V106** The index file as a data structure | 13:39 | 59 MB | 33 % | PASS; warn E5 | Nothing changed. | Five terminal windows between 7:02 and 9:50 carry the title `labs/verify-all.sh` (section 6, item 3). The note that these numbers differ on every machine is on screen only as that direction's source; it is not read. |
| **V107** The reftable backend, SHA-1 and SHA-256 | 16:51 | 71 MB | 36 % | PASS; warn E5,E6 | Nothing needed changing. | The card "GitHub, not Git." is three words on an empty frame for 36 s (6:18) while its paragraph, with the "unverified" statement, is read. |
| **V108** The commit-graph, the multi-pack-index, bitmaps | 16:37 | 73 MB | 37 % | PASS; warn E5,E6 | Final-pass item: the diagram ended on the row "13 maybe, 81 definitely not" and its narration pointed at it, 80 s before the prediction that asks for these two numbers. The row now arrives in the production example, after the reveal, and the sentence reads "How many of each, Git will report itself in a moment". The state table (40 words, 5 s of silence) is read. | None seen. |
| **V109** The fetch conversation, shallow and partial clones | 19:08 | 82 MB | 26 % | PASS; warn E5,E6 | Nothing changed. Fix list: the "absent from this clone" style is in use. | The card "GitHub, not Git." stays 27 s; its second half is under the paragraph about `--single-branch`. The root-cause box stands 7.2 s in silence (10:55). |
| **V110** Bundles, and when each scale feature matters | 12:28 | 54 MB | 30 % | PASS; warn E5 | Nothing changed. Fix list: tag position verified (section 3). | A key point at about 1:20 is a tall, mostly empty panel (library). |
| **V111** Monorepo versus polyrepo, sparse-checkout | 15:15 | 64 MB | 21 % | PASS; warn E5,E6 | Interview question: the three-places picture, which is the answer, came on screen 2 s after the question; the question card now stays. The state table has one sentence over its last page. | The first two pages of the state table stand 3 s each in silence. |

### Imperfections that apply to several videos

- **Text or a table held in silence** (3 to 12 s): V091, V094, V095, V097, V099, V111; root-cause boxes in V097, V101, V109. Seven such places were given a sentence in this pass; the others would each need one more.
- **Caveats in `[ON SCREEN]` directions.** A quoted direction shows only its quotation, and an unquoted "Lower third" direction shows only a badge or nothing. Nine caveats were lost this way; seven are now read (V090, V091, V093, V096, V097 three). Still not read: V090 line 443, V096 line 192, V097 line 383, V106 line 186. None of the four is an "Unverified" statement; each is a note on the source or on reproducibility.
- **A caption brought back by `say:` lands on the wrong picture** (V090, V091): section 6, item 4.
- **A step placed at 82 % of a short paragraph is cut** (V089, V091 twice, V092, V105). All beats of this kind were listed from the storyboards (27) and their last frames looked at; the five that were cut are fixed.
- **Edges close to IDs** (V089, V094, V097, V100): fixed with wider columns or a row above the line in eight graphs.
- **Explainer share**: 19 to 37 %; V094, V097 (20 %), V099 (19 %) are below the aim of a quarter.
- **Terminals type before they are spoken about**: the pipeline's normal behaviour; holds of 7 to 8 s in V090, V093, V094, V096, V102.

## 3. Fix-list and final-pass items

| Item | Outcome |
|---|---|
| V090, V094: parent links inferred | **Closed.** V090: `labs/run ch14c/lab-14-3-pre-push-guard` replayed in a scratch sandbox: `18e1b38` on `20aa35f` on `eafde45`, `f1edb7c` on `18e1b38`, as drawn. V094: the links are those of the script's own `git log --graph` transcripts. |
| V105: links taken from V100/V101; V110: tag `schemas/v1.1.0` on `100bb99` | **Closed.** V105 agrees with the `git log --graph --oneline` transcript in V100. V110: `labs/run ch26/bundles` replayed; `schemas/v1.1.0^{commit}` is `100bb99`, and `6d3aa59`, `aa0428a`, `100bb99` are a chain. |
| V103, V109: ghost style to the new styles | **Closed by the scene pass, seen.** V103 draws `728ac29` dashed and not faded with the note "only the reflog of HEAD names it"; V109 draws `d259a34` hatched behind the boundary. |
| V108 try-it `ls .git/objects/info` | **Closed by the scene pass, seen.** The answer is definite and the transcript shows the empty listing. |
| V108: prediction given away by its diagram | **Closed** (section 2). Seen at 8:31, 9:46, 9:51 and 14:03. |
| V093, V095 failed their voice build; V090 | **Closed.** All three built and PASS. V095 needed a wording change (section 6, item 1). |
| V109, V110 need rebuilding | **Nothing to do.** Both pass QC in the builds of 13:28 and 13:32 today. |
| V107, V108: older peak level | V108 was rebuilt. V107 is the build of 13:21 today; QC PASS. |
| Contraction passes: spot-check subtitles | **Closed for this range.** Every "it's" in the 23 subtitle files was read in its sentence (about 100); none is wrong. |
| All ranges: no diagram held in silence | **Checked.** Every `[DIAGRAM]` drawing has narration. Root-cause boxes held in silence: two now have a sentence (V092, V105), three do not (V097, V101, V109). |
| All ranges: one wording per term | **Open** (final pass, with the glossary). |

## 4. Other things corrected

- Presenter notes read aloud: V096 "Say this on screen now, before the first replay", V091 "on the first slide". "Point at each commit on the graph" (V101) was left; the course uses it to address the viewer.
- After each edit `python3 tools/inject.py --check` reports 0 problems for the script. `python3 tools/check_course.py` reports 0 problems at the end (during the pass it reported three, all in `out/QC-SUMMARY.md`: object IDs quoted in the entries of the then failing videos).
- Narration growth: V097 3.0 %, V096 2.3 %, V091 2.2 %, V104 1.9 %, V094 1.6 %, V108 1.3 %, V093 1.1 %, V111 1.0 %, V092 0.9 %, V105 0.7 %, V090 0.6 %; no fact was added: every new sentence is made of the words of a direction, a table or a root-cause box of the same script.
- Only `[ANIMATION]` lines and the narration sentences named here were changed. No snippet, table, heading or `[ON SCREEN]` line was touched. Nothing in `tools/` was edited.

## 5. What was verified by looking, and what was not

Verified in frames of the finished videos: every item in the "What was fixed" column; the absence of overlapping or cut text and of literal underscores in captions and labels (none found); that no quiz is asked over a picture that shows its answer (all 46 pauses that stand over a scene, a table or terminal output were listed and judged; three cases found and fixed: V104, V108, V111); that scene captions fit the paragraph being read at the sampled moments (two wrong pictures found and fixed: V090, V091).

Not verified: frames between the samples; the unchanged parts of a video after its rebuild; the audio; the subtitles beyond the contraction and presenter-note read and the QC tool's checks; items A13, F9, F10, G4, G5 and I8 to I10 of the checklist (player, chapter clicks, thumbnails, upload).

## 6. Library defects and limits found (nothing in `tools/` was edited)

| # | Where seen | Defect | Workaround used |
|---|---|---|---|
| 1 | V095 line 317 | The voice step refuses a sentence that ends in a ten-digit ID: "Remember the first characters of the checksum: 0269885262." lasts 7.12 s in 23 of 24 takes; the bounds allow 4.2 to 5.3 s, because `pace_units()` counts the ID as one word (1.12 words/s, below the wide bound of 1.31, so the three-takes rule cannot accept it). The video cannot be built. | sentence shortened to seven words ("Remember the start of the checksum: ..."), which the short-piece rule accepts (6.95 s) |
| 2 | V090 443, V093 936, V096 192 and 378, V097 725 | An unquoted `[ON SCREEN]` "Lower third" direction is shown as a badge on the next key point, as a card held 5 s in silence, or not at all, depending on what follows; its text is never read. No warning. | the caveat as narration |
| 3 | V106 line 186 | The first code span of a `[TERMINAL]` direction becomes the window title: `labs/verify-all.sh`, the script the direction says does not reproduce this transcript, and the title is kept for four later command windows. | none |
| 4 | V090 line 88, V091 lines 94 to 102 | `say:` after `end` brings back "the most recent scene" by position in the script, which after a `step: id.x` to an earlier scene is not the scene the editor last addressed; the caption lands on an unrelated picture. No warning. | `step: <id>.<last step>` before the `say:` |
| 5 | V103 line 437 | A `say:` tag on a graph with panels draws the caption over the panel names; `say_state_1=` in the tag puts it on the caption line. | `say_state_1=` |
| 6 | V089, V091, V092, V105 | A step that starts at the default 82 % of a short paragraph is cut when the next beat is another slide (3A report, item 4). | `at_<step>=` |
| 7 | V091 8:38 | A seven-column table breaks a word inside the word ("unchange / d") (3A, item 5). | none |
| 8 | V095 6:53, V110 1:20 | Key points in the card layout: one line at the top of a tall empty panel (3A, item 6). | none |
| 9 | V089 2:30 to 12:24 | `gates` with groups: the tick mark of a passed gate touches the group title above it. | none |
| 10 | V091 8:38 and 13:00 | `submodule`: the `link:` arrow runs behind the HEAD chip of the left panel and the branch chip of the right one. | none |
| 11 | V098 3:07, 4:01 | `cards` with a question and five cards, or three cards without sub-lines: placed in the lower half, upper half empty. | none |
| 12 | V107 6:18, V109 5:25 | A quoted direction of three words is a card on an empty frame for as long as the paragraphs after it last (36 s and 27 s). | none |

## 7. The sound (not listened to)

Nobody listened to any of the 23 videos. What could be established without ears:

- `make.sh qc V089-V111`: 23 PASS. Loudness, peak, clipping, silence and the pace of every beat are inside the tool's bounds; every voice clip has its verification mark.
- **Clips accepted under the three-identical-takes rule, to be listened to once: one.**
  - **V095, 8:52**: "Now add a model of 1,200,000 bytes and commit it together with .gitattributes." (15 words in 4.38 s; 19.6 letters per second against a bound of 19).
- Two more places worth one listen, although the tool does not flag them:
  - **V095, 8:56**: "Remember the start of the checksum: 0269885262." (6.95 s; the sentence reworded in this pass).
  - **V090, about 6:01**: "Keep the tripwires from the last video. You place them in your own workshop. They do nothing in a colleague's. You can step over them." (the piece that had a burst of noise between two sentences in every take and is now spoken sentence by sentence; `QC_CHECKLIST.md`, C1).
- The voice builds: 15 videos, each built at the first attempt except V095 (three refused attempts on the sentence of section 6, item 1, then built at once after the rewording). The main voice run was working on V112 onward at the same time.
- **The text given to the voice** (`.cache/tts/VNNN.spoken.txt`) was scanned for all 23 for symbol wording. Odd wordings that remain:

| Video | The voice is given | Remark |
|---|---|---|
| V100, V101, V105 | "v 1 point 0 point 0 caret, empty curly braces", "caret, commit in curly braces" | consistent; the brace is named once |
| V100, V102, V105 | "percent, objectsize in parentheses", "percent, committerdate colon short in parentheses" | format placeholders spelled out; long |
| V111 | "slash libs slash with exclamation mark slash libs slash star slash" | a sparse-checkout pattern read symbol by symbol |
| V098, V103 | "git F S check" | `fsck`, from the builder's table |
| V109 | "it's the silently of the hook" | the script's own wording (script, not the voice rules) |
| V100 line 213 | "how many parent headers there?" | the script's own wording |

## 8. Verification at the end

- `make.sh qc V089-V111` at 15:38: 23 PASS, 0 failed. ffprobe and `VNNN.build.json` for all 23: section 1; the script hash in every storyboard equals the script on disk, and every MP4 is newer than its script.
- `make.sh storyboard`: no warning and no notice for any of the 23.
- Rebuilds ran one at a time from a detached queue started with `setopt NO_BG_NICE` (storyboard, slides and animate under `nice -n 20`, voice at normal priority), 14:07 to 15:37. `--look` renders one at a time (10 renders, prefix `b3b-`); the look folders and all frames are deleted. Log: `video/production/.cache/inspect-b3b/rebuild.log`; working notes: `video/production/.cache/inspect-b3b-progress.md`.
- Times in this report are from the final builds.
- No `git` command was run in the course directory (two labs were replayed, and their repositories read, in a scratchpad sandbox outside it), nothing was run against GitHub, no video outside V089 to V111 was touched, and nothing in `tools/` was edited.
