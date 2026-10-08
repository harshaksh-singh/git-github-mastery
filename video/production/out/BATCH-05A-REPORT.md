# Batch 5A (V134 to V155): finishing report

Written 2026-10-09 by the finishing inspector of V134 to V155 (GitHub rules, CODEOWNERS, signatures, the CLI and API, GitHub Actions). Voice: the macOS voice Tara at 165 words per minute. Every video carries the animation layer and was voiced with the repaired voice step. The form follows `BATCH-04-REPORT.md`.

## 1. Result

- **22 of 22 videos built, 22 of 22 PASS from the QC tool** (`make.sh qc V134-V155`, run at 02:05 after the last build): 1920x1080, 30/1 fps, H.264 and AAC, picture and sound equal within 0.011 s, built from the script as it is now, storyboards with no warning and no notice. Warnings: subtitle line length (E5, all 22) and reading speed (E6, all 22); pace warnings (C1/C2, three identical takes) in V137, V140, V144, V146, V147 (section 7).
- Total length 6 h 52 min, 1.79 GB. Files: `video/production/out/VNNN.mp4` with `.srt`, `.chapters.txt`, `.build.json`; QC reports in `video/production/out/qc/`.
- **At the start** (23:52 on 8 Oct) 20 passed, **V135 failed QC** (C4: a 3 s hold at 9:11 only 74 % silent; it was the first page of a textbook list shown in silence with its bullet sounds, section 2), and **V144 had no MP4** (its voice build had failed on "On a runner the path is given to each step." while the machine was busy).
- **V144** was voiced first, alone, at 23:54: the sentence was spoken at the first attempt; QC PASS (00:03).
- **20 videos were rebuilt in full** (storyboard, slides, animate under `nice -n 20`; voice at normal priority from a shell started with `setopt NO_BG_NICE`; QC niced; one at a time from a detached queue, 00:17 to 02:02): V134 to V140, V142 to V154. Each was built once (V144 twice: the voice-only build above, then the full build after its script fix). **Every voice build succeeded at the first attempt; no sentence was refused.**
- **Not rebuilt:** V141 and V155 (builds of the main voice run of 8 Oct; nothing needed changing).
- **How they were inspected.** From frames of the finished MP4s with the script, the storyboard and the `.srt` open: the last moment of every explainer-scene beat, the middle of each long scene and long beat, every ASCII drawing, every silent hold and prediction pause, and six frames spread over the length: 22 to 47 frames per video, 758 in all, looked at as 135 contact sheets of six half-size frames, with full-resolution crops and extra frames where a sheet left a doubt (about 25). Storyboard scans by script for: silent holds on non-terminal slides, callouts under unrelated narration, late steps, graph paragraphs that play only `grow`, inherited key-point headlines, caveat words on screen and in nearby narration, interview sections (all 22 hold only the question card). After each rebuild the changed places were looked at again in the new MP4 (2 to 6 frames each, about 70 in all); the unchanged parts of a rebuilt video were not looked at a second time. Proposed scene changes were checked with `--look` first (prefix `b5a-`, one at a time, 9 renders).
- **Not done: nobody listened.** No audio was heard at any point. Section 7 lists what was done for the sound.

"Explainer scenes" is the share of the running time during which a library scene or an animated commit graph is on screen. "QC tool" is the result of `make.sh qc VNNN`.

## 2. Per video

All walkthrough fixes marked "headline" are the same change (section 3, common imperfection 1): the first sentence of the GitHub walkthrough paragraph was made a bold lead-in, no word changed, so its key points no longer carry the headline of the last terminal step.

| Video | Length | Size | Explainer scenes | QC tool | What was fixed | Still imperfect |
|---|---|---|---|---|---|---|
| **V134** Seeing and managing rules, "why can't I merge?" | 21:33 | 92 MB | 35 % | PASS; warn E5,E6 | Slides of the timed-out render: every sampled frame correct. Graph `dq` (13:11): the paragraph naming `9042b9e` "Merge main into docs/queues" showed bare commits with no labels or notes for 14.7 s (the `step: verdict` tag left only `grow` for it); now labels and notes arrive at 18 % (13:19). Presenter note "Point at the last line of the fetch output" now "Look at ...". | Walkthrough key points (13:42) keep the headline "Step 3" (first sentence too long for a lead-in). The merge-commit mark touches the corner of the `origin/docs/queues` chip (13:32). |
| **V135** CODEOWNERS: what, where, syntax, last match wins | 17:39 | 75 MB | 29 % | PASS (was FAIL C4); warn E5,E6 | The second `[DIAGRAM]` direction (unquoted, names section 19.16) is drawn as the textbook's exercise list 19.16 in two pages, and both stood 3 s in silence (C4 fail at 9:11), then the root-cause box of 19.5 for 8.2 s in silence. The sentence "The other four question marks are yours ..." moved after the direction, plus "For each, mark the matching lines and keep the last." (the direction's words) and one root-cause sentence: nothing silent left (9:05 to 9:23). Headline. | The list shows the textbook's exercises 10 to 12 (text this script does not state), now read over but not read out (library, section 6 #1). |
| **V136** CODEOWNERS in force | 19:55 | 91 MB | 26 % | PASS; warn E5,E6 | `match` scene header drawn with literal underscores ".github/CODEOWNERS_on_origin/main" (12:56): header `.github/CODEOWNERS`, the base version named in the title. Recap (18:46): the production caption "Under the base version the last line owns .github/CODEOWNERS ..." stood over the recap sentence; now the scene's own caption "Review requests come from THIS copy: the base branch". Presenter note "On screen, name the controls by function" now "On your screen, know the controls by their function". Headline. | None seen. |
| **V137** Signatures, SSH signing end to end | 17:34 | 75 MB | 30 % | PASS; warn C2,E5,E6 | Root-cause box of 14B.16 7.5 s in silence (7:45): one sentence from its root-cause line. "Point at the file name" now "Look at the file name". | Graph "The result letters of git log -4" (12:03) stands under the tag prediction paragraph (shows nothing about the tag). |
| **V138** What a signature covers, author spoofing | 18:37 | 83 MB | 24 % | PASS; warn E5,E6 | The `[ON SCREEN]` "Lower third: GitHub ... According to GitHub's documentation ... "rebase and merge" are not signed at all" stood 5 s in silence (11:18) and the documented statement was never read; now read as one paragraph of its own sentences (11:25). | The card is drawn cut after the quoted words "rebase and merge" (library, section 6 #3). Hook shows the textbook's "GitHub, not Git" box instead of the quoted line (library, #2). |
| **V139** Signatures on GitHub | 17:23 | 75 MB | 32 % | PASS; warn E5,E6 | Headline. | None seen. |
| **V140** gh, gh api, REST, rate limits, webhooks, Apps | 23:00 | 97 MB | 27 % | PASS; warn C2,E5,E6 | Callout "Unverified. Webhook delivery retries and signature validation were not researched ..." 5 s in silence, never read (10:24): now read (10:29). | Walkthrough key points (17:00) keep the headline "Step 6: the lab replay for API queries" (first sentence too long). |
| **V141** Gate briefing: GitHub | 10:27 | 45 MB | 33 % | PASS; warn E5,E6 | Nothing needed changing (not rebuilt). | None seen. |
| **V142** The Actions model, YAML read carefully | 19:05 | 81 MB | 25 % | PASS; warn E5,E6 | `ci` card (2:58, recap): the file name ".github/workflows/01-tests.yml" ran over the right edge of its box and the card read `on: push` for a file with two events; now `file=off` (3:14). Two "Unverified" callouts (YAML booleans; merge keys) were on screen 2 s under the step headings and never read: one paragraph each from their own words (10:58, 12:19). Headline. | Step name stays "Run the tests" (the file's "... with the standard library" does not fit the box, look `b5a-v142a`); the walk table at 13:46 carries the full name. Hook draws the textbook's four questions of 20A.1 (they are the script's own direction here). |
| **V143** Events, filters, contexts, env/vars/secrets | 21:05 | 95 MB | 25 % | PASS; warn E5,E6 | Headline. | Hook (0:04 to 0:42): the quoted "Question 3 of section 20A.1: ..." is drawn as the textbook's whole list of four questions (library, #2). Try-it card 13:58 keeps the headline "Step 2: what two dots would say". |
| **V144** Shells, passing data between steps and jobs | 14:49 | 62 MB | 25 % | PASS; warn C2,E5,E6 | Final-pass item: built; the sentence voiced at the first attempt. Quiz (3:00) asked over the template table that shows its answer (and the answer says "look at the first two rows again"): now framed "Quick quiz, with the table still in front of you." Headline. | The quiz remains a reading question over its table, by design now. |
| **V145** actions/checkout: one commit, no tags, merge ref | 18:34 | 84 MB | 20 % | PASS; warn E5,E6 | Try-it "put one finger on the commit your laptop tested, and another on the commit the runner tested" (8:35) stood over notes "your HEAD" / "runner HEAD (detached)": the notes now arrive in a new state with the answer (8:46; look `b5a-v145a`). Two root-cause boxes of 20A.8 7.2 s and 5.0 s in silence: one sentence each (8:51, 8:58). | The second box (unquoted direction with quote marks inside) is drawn as a 100-word quotation (library, #3). Hook: the textbook's question list (#2). Explainer share 20 %. |
| **V146** Jobs, matrix, caching, artifacts | 20:15 | 88 MB | 22 % | PASS; warn C2,E5,E6 | Two "Unverified" callouts (matrix check names 6:46; aggregation with continue-on-error 15:03) stood under unrelated paragraphs and were never read: read now (6:56, 15:24). Root-cause box of 20A.11 6.4 s silent: one sentence (12:27). Headline. | 14:20: the 5 s card "Screen walkthrough, with workflows/10-matrix.yml on screen first" stays silent (a title before the run scene). |
| **V147** Workflows 1 to 5, line by line | 20:56 | 90 MB | 25 % | PASS; warn C1,C2,E5,E6 | Headline (14:32). | None seen. |
| **V148** Workflows 6, 7, 10, action versions, Node 24 | 22:36 | 101 MB | 28 % | PASS; warn E5,E6 | `gates` scene (5:21): the label "Job summary" was broken "Job summar / y"; now "Summary". The result "built, never pushed" arrived at 82 % of a 4.1 s sentence (0.7 s on screen): now at 25 % (`at_result`), visible about 1.6 s. Headline. | The result is still on screen only about 1.6 s. The quiz card at 13:46 carries the library's decorative hash "2e76f67" (not in the script; library, #5). |
| **V149** Environments, staging, promotion | 23:06 | 101 MB | 24 % | PASS; warn E5,E6 | Root-cause box of 20B.4 8.2 s silent: one sentence (12:46). Fix-list: graph link `e39e6de` ← `57c8425` verified in the sandbox (section 3). Headline. | Hook shows the textbook's "GitHub, not Git" box instead of the quoted question (#2). IDs inside a shaded range (16:30, 17:31) are grey on grey-green, weak at 720p. The callout "Unverified." (5:47) shows only the word; the paragraph read over it says the conflict "couldn't be resolved" but not the word "unverified". |
| **V150** Concurrency, reusable workflows, actions | 20:13 | 88 MB | 25 % | PASS; warn E5,E6 | DIAGRAM section: the walk table's third row ("queue: max") arrived 1.2 s before the scene left: now at 50 % (12:14); the default drawing then came back 5.4 s in silence (fenceless second `[DIAGRAM]`): now read over with one paragraph from the direction's words (12:21). Headline. | None seen. |
| **V151** Publishing a container image, releases | 15:27 | 65 MB | 25 % | PASS; warn E5,E6 | Three-trees scene (9:10 to 9:45) labelled the commit "c1" (library default): now `57c8425` with `main`/HEAD, as the graph before it. Headline. | None seen. |
| **V152** Runners, limits, billing, investigation order | 21:50 | 98 MB | 32 % | PASS; warn E5,E6 | Graph `sides` (15:16 to 16:35): an edge ran through the words "test merge" and a dashed edge crossed it; the branch is now drawn above `main` and every label is clear in the three states (look `b5a-v152b`). Headline. | Hook shows the textbook's "GitHub, not Git" box instead of the two quoted questions (#2). |
| **V153** Passes locally, fails on Actions | 17:59 | 77 MB | 30 % | PASS; warn E5,E6 | The 14-row table of 20B.12: page 1 stood 3 s in silence (2:25): now one sentence per page. Root-cause box 6.8 s silent: one sentence (8:09). | None seen. |
| **V154** Required checks pending, instruments, act | 19:54 | 83 MB | 24 % | PASS; warn E5,E6 | Headline (the walkthrough key points carried "The tempting repair"). | None seen. |
| **V155** Gate briefing: Actions | 9:56 | 43 MB | 26 % | PASS; warn E5,E6 | Nothing changed (not rebuilt). | Quiz 3:52 stands over the "Two orders" boxes headed "still above the log" / "the log and after": a strong hint (the answer row arrives with the answer). |

### Imperfections that apply to several videos

1. **Inherited headlines on GitHub walkthroughs** (14 videos): a bold lead-in headline stays until the next one, so the walkthrough key points carried the last terminal step's heading ("Step 5: a tab", "The tempting repair"). Fixed in V135, V136, V139, V142, V143, V144, V146 to V152, V154 by making the walkthrough's first sentence a lead-in (narration checked identical in a sandbox storyboard). Left in V134 and V140 (first sentence longer than 14 words). The same mechanism leaves stale headlines on some quiz and try-it cards ("In one sentence", "Matrix. In one sentence", "Precisely,"); these were not changed.
2. **Root-cause boxes held in silence**: V135, V137, V145 (two), V146, V149, V153: each now has one sentence from its own root-cause line.
3. **Caveats shown and not read**: "Unverified" callouts in V140, V142 (two), V146 (two) and the documented GitHub statement in V138 were on screen and never spoken; all are read now. V149's bare "Unverified." label is the one place where the word itself is not spoken.
4. **Quoted on-screen directions that name a section are drawn as a textbook block** (V138, V143, V144, V145, V149, V152 hooks): the viewer sees a textbook box or question list, not the quoted line. The directions may not be edited; library defect #2.
5. **Explainer share**: 20 to 35 %; V145 (20 %) and V146 (22 %) are below a quarter.

## 3. Fix-list and final-pass items

| Item | Outcome |
|---|---|
| Final pass: V144 failed its voice build on 'On a runner the path is given to each step.' | **Closed.** Voiced at the first attempt on a calm machine (00:03), again in the full build (01:02); the sentence is in the subtitles and the spoken record. QC PASS. |
| Final pass: V134 slides re-rendered after a timeout | **Closed, seen.** 47 frames of the old build and the changed places of the rebuild: every slide drawn and correct. |
| Final pass: V142 full-screen file direction renders as a placeholder | **Checked, left.** "The file `workflows/01-tests.yml`, full screen." is drawn as a card with the file name for 2.7 s under "Now read workflow 1 in the order you learned" (12:35); the walk table of the file follows. It works as a title; the file itself is not shown. |
| V143 to V155 `ci`/`run` cards | **Checked.** The only `ci` cards are V142 (fixed, see V142) and V143 (`file=off`, `on: pull_request`, "the paths filter matched nothing"). `run` scenes in V142, V144, V146 (two), V147, V148, V149 (two), V154 carry only the script's labels; the inferred designs (V154 "The robust design: an inference from these rules") say so in the title and the narration. |
| V135: "the five question marks are yours" vs four | **Closed by the scene pass, seen.** Direction and narration both say four remain. |
| V137: "most often N" for `%G?` | **Closed by the scene pass.** Narration: "With no signing configured, it's most often N three times". |
| V140: ghost style after `git branch -D` | **Closed by the scene pass, seen.** Third state uses `reflog:` (dashed, not faded), 16:42. |
| V142: step name "Run the tests" vs the file's name | **Kept** (section 2, V142); look `b5a-v142a` shows the full name running out of the box. |
| V146: Step 2's prediction given away by Step 1 | **Closed by the scene pass.** The prediction is now worded "You've seen the README commit leave the hash alone. Now the lock file itself changes." |
| V147: `ci` card `on: push`; "not executed" visible; ruff question | **Closed.** V147 has no `ci` card now (the item applied to V142, fixed). The gates scene "Workflow 1 on the breaking pull request" shows "predicted, not executed" and the narration says "by the documentation". The ruff question is answered from the lab manual's recorded local run (ruff 0.15.21). |
| V148 (tag-push prediction), V152 (billing quiz), V155 quiz: derived answers | **Re-checked.** V148: `workflows/03-build.yml` and `06-docker-image.yml` are the only files with a tag filter (`tags: ["v*"]`); the four tag rules and "with the default flavor, a semver tag also produces `latest`" are in textbook ch20a line 1149; the table is titled "Derived from the documentation, not executed" and the narration says so. V152: "Each job is rounded up to a whole minute" is textbook ch20b line 549; the quiz applies it to its own numbers. V155: the answer follows from the investigation order (log ninth) taught in V152; the video does not call it "derived". |
| V149: link `e39e6de` ← `57c8425` from a sandbox replay | **Verified.** `labs/run ch20b/lab-27-4-promotion` replayed with `GIT_MASTERY_LABS` in the scratchpad: `e39e6de` has parent `57c8425`; `fe34a26 (HEAD -> main)` merges `57c8425` and `e39e6de`; `57c8425` ← `197d992` ← `c4b5de2 (tag: v1.1.0)`. The graph is right. |
| All ranges: no diagram held in silence | **Checked.** Every silent hold on a non-terminal slide in the 22 storyboards is now read over (V135, V137, V138, V140, V145, V146, V149, V150, V153 fixed), except the 5 s walkthrough title card in V146 (14:20). |
| All ranges: caveats read aloud | **Checked** from the storyboards (every slide carrying "unverified", "documented", "announced", "not executed", "inference", "derived" compared with the narration around it), spot-checked in the subtitles. Fixed: V138, V140, V142, V146. Remaining: V149's one-word "Unverified." label. |
| All ranges: one wording per term | **Open** (final pass, with the glossary). |

## 4. Other things corrected

- After each edit `python3 tools/inject.py --check` reported 0 problems for the script, and `python3 tools/check_course.py` reports 0 problems at the end.
- Narration growth (paragraph words): V146 2.9 %, V142 2.5 %, V138 1.5 %, V135 1.3 %, V145 1.1 %, V150 1.0 %, V153 0.9 %, V140 0.8 %, V137 0.6 %, V149 0.5 %, V144 0.4 %, V136 0.1 %; others 0. No fact was added: every new sentence is made of the words of a root-cause box, a callout, a direction or the same paragraph.
- Changed: `[ANIMATION]` lines; narration sentences named in section 2; bold markers on the first sentence of walkthrough paragraphs. No snippet, YAML, table, heading or direction was touched. Nothing in `tools/` was edited.
- Every edited script was storyboarded in a scratch sandbox first (`VIDEO_WORK_DIR` in the scratchpad): 0 warnings, 0 notices. The scripts as they were before this pass: `video/production/.cache/inspect-b5a/orig/`.

## 5. What was verified by looking, and what was not

Verified in frames of the finished videos: every item in the "What was fixed" column, in the rebuilt MP4; the absence of overlapping or cut text and of literal underscores in captions and labels at the sampled moments, except where listed as still imperfect; that no interview question is followed by an answer picture (all 22); that quizzes, predictions and try-its were not asked over a picture that shows their answer at the sampled moments (V145 fixed, V144 reframed, V155 left as a hint); that scene captions fit the paragraph being read at the sampled moments (V136 recap fixed).

Not verified: frames between the samples; the unchanged parts of a rebuilt video after its rebuild; the audio; the subtitles beyond the scans of section 7 and the QC tool's checks; checklist items A13, C6, C7, E9 (need ears), F9, F10, G4, G5 and I8 to I10 (player, chapter clicks, thumbnails, upload).

## 6. Library defects and limits found (nothing in `tools/` was edited)

| # | Where seen | Defect | Workaround used |
|---|---|---|---|
| 1 | V135 9:05 | An unquoted `[DIAGRAM]` direction without a fence that names a section ("... the pattern exercises of section 19.16") is drawn as that section's list (two pages, text the script does not state) and held in silence; a `step:` tag before or after it does not replace it. No warning. | narration moved over it |
| 2 | V138, V143, V144, V145, V149, V152 hooks | A quoted `[ON SCREEN]` direction that also names a section ("One question from section 20B.1: "...") is drawn as a textbook block of that section (the "GitHub, not Git" box, or the whole question list), not as the quotation: `resolve_textbook` is tried before `quote_callout`. | none; open |
| 3 | V138 11:18, V145 8:58 | `quote_callout` treats any direction with two quote marks as a quotation: V138 drops a tail of more than 8 words ("are not signed at all"); V145's unquoted root-cause box becomes a 100-word quotation that starts mid-sentence. | narration reads the content |
| 4 | 14 videos | A bold lead-in's headline is inherited by every later key point until the next lead-in, across terminal steps into the GitHub walkthrough. | lead-in on the walkthrough's first sentence |
| 5 | V148 13:46 | The quiz key-point icon draws a hash "2e76f67" that is in no script. | none |
| 6 | V142 2:58 | `ci` with `file=`: the workflow box is sized for `.github/workflows/ci.yml`; a longer file name runs out of it; the layout check says clean. The step names (`steps`) do not wrap either. | `file=off` |
| 7 | V148 4:21 | `gates` wraps a label inside a word ("Job summar / y"). | shorter label |
| 8 | V151 9:10 | `trees` shows the default commit label "c1" unless `commits=` is given. | `commits=` |
| 9 | V134 13:11 | A `graph` scene with a `step:` tag on a later paragraph plays only `grow` (no labels, no notes) over the first paragraph; no warning. | `step: state-1` |
| 10 | V149 16:30 | IDs inside a `range:` band are grey on grey-green; weak at 720p. | none |

## 7. The sound (not listened to)

Nobody listened to any of the 22 videos. What could be established without ears:

- `make.sh qc V134-V155`: 22 PASS. Loudness, peak, clipping, silence and the pace of every beat are inside the tool's bounds or accepted under the three-identical-takes rule; every voice clip has its verification mark.
- **Clips accepted under the three-identical-takes rule, to be listened to once:**

| Video | Time | Sentence | Measured |
|---|---|---|---|
| V137 | 2:47 | "Precisely. Git computes the object without a signature, hands those bytes to a signing program ..." (a part of the beat) | 3.04 words/s, 12.6 letters/s |
| V140 | 4:13 | "Now the labels, because this is the objective people skip. G H pr view, G H pr c..." (a part) | 2.77 words/s, 9.9 letters/s |
| V144 | 9:48 | "Read the file in the order you know. Trigger: pushes t..." (a part) | 2.99 words/s, 12.5 letters/s |
| V146 | 16:24 | "An if on a job that is a required check." | 4.69 words/s, 14.1 letters/s |
| V147 | 7:49 | "Workflow 5: Java tests with Maven." | 4.00 words/s, 20.0 letters/s |
| V147 | 17:16 | "The diagnosis is the one you can now do in your head. Trigger of workflow 5: a p..." (a part) | 3.01 words/s, 12.3 letters/s |

- Places worth one listen although the tool does not flag them:
  - **V144** (the sentence of the final-pass item): "On a runner the path is given to each step." (9:05 to 9:11).
  - **V144, 2:41 and 13:47**: "bash dash dash noprofile dash dash norc dash e o pipefail".
  - **V148, 4:22 to 4:53**: "type equals ref, event equals branch ... type equals semver ... sha dash plus the short commit ID" (long, symbol by symbol).
  - **V135, 10:21 to 10:45**: paths read slash by slash ("slash docs slash ... guide slash docs slash a dot M D ... star star slash logs").
  - **V137, 6:02 and 11:08**: "percent capital G question mark ... percent capital G capital S ...".
- The voice builds: 21 builds (V144 twice), each at the first attempt, while the main run worked on V156 onward under the same voice lock.
- **The text given to the voice** (`.cache/tts/VNNN.spoken.txt`, all 22) was scanned for symbol wording; the storyboard narration for wrong contractions (101 "it's", none possessive; the contracted quotations in V135 and V136 are contracted in the textbook's quotation too) and for presenter notes (three reworded: V134, V136, V137). Odd but consistent wordings: "yammel" for YAML; "dash dash json ... dash dash jq" (V140); "a form starting with dollar slash" (V150); "if with exclamation mark cancelled" (V143, V147); "dot git hub slash workflows slash" (V136). "Never show a real key or token on screen" (V139, V149) is advice to the viewer and was left.

## 8. Verification at the end

- `make.sh qc V134-V155` at 02:05: 22 PASS, 0 failed. ffprobe and `VNNN.build.json` for all 22: section 1; the script hash in every storyboard equals the script on disk, and every MP4 is newer than its script.
- Storyboards: no warning and no notice for any of the 22. `python3 tools/check_course.py`: 0 problems.
- Disk: 13 to 14 GB free throughout (the queue stopped itself below 8 GB; it never had to).
- Rebuilds ran one at a time from a detached queue started with `setopt NO_BG_NICE`, 23:54 to 02:02. `--look` renders one at a time (prefix `b5a-`); look folders and all frames are deleted. Log: `video/production/.cache/inspect-b5a/rebuild.log` (and `rebuild-0.log`); working notes: `video/production/.cache/inspect-b5a-progress.md`.
- Times in this report are from the final builds.
- No `git` command was run in the course directory (one lab was replayed, and its repository read, in a scratchpad sandbox outside it), nothing was run against GitHub, no video outside V134 to V155 was touched, and nothing in `tools/` was edited.
