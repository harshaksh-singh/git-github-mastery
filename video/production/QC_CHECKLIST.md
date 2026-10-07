# Quality control checklist for the course videos

What a video editor and a YouTube publisher check before a video of this course goes out: a screen-recorded lesson with animation, a computer voice (or a recorded narrator), subtitles, chapters and a thumbnail.

Every item says what is checked, when it passes, and who checks it:

| Who | Meaning |
|---|---|
| **tool** | `video/production/make.sh qc V008` (`tools/video_qc.py`) measures it. The result is in `video/production/out/qc/V008.qc.json` and in `video/production/out/QC-SUMMARY.md`. |
| **eyes** | A person looks at frames with the script open. No program here can judge it. |
| **ears** | A person listens, with headphones. No program here can judge it: the tool measures loudness, silence and pace, not whether a word is pronounced correctly or the voice sounds right. |

A video is ready for upload when the tool says PASS **and** a person has done the "eyes" and "ears" items. The tool's PASS alone is not a statement about how the video looks or sounds.

## How to run it

```bash
video/production/make.sh qc V008            # one video
video/production/make.sh qc V067-V107       # a range
video/production/make.sh qc all             # every video; a video without an MP4 is "not built", not a failure
video/production/make.sh qc --deep V008     # decode every frame, not only the key frames (items A9 and D1)
video/production/make.sh qc --summary       # write the summary table again from the reports on disk
video/production/make.sh qc --selftest      # test the tool's own parsers; reads no video
```

The tool only reads. It builds nothing, speaks nothing and re-encodes nothing. A check takes 5 to 10 seconds per video (measured with builds running at the same time; the first video after a pause, or a very busy machine, can take a minute or two). The exit code is 1 if a checked video fails.

Results per item: PASS, FAIL, WARN (does not fail the video; look at it), N/A (could not be measured here, with the reason).

## A. File and encoding

| # | What is checked | Passes when | Who |
|---|---|---|---|
| A1 | Container and streams | MP4; exactly one video and one audio stream | tool |
| A2 | Video codec | H.264 | tool |
| A3 | Picture size | 1920x1080, square pixels | tool |
| A4 | Frame rate | 30/1 nominal, average within 0.01, every frame within 1 ms of its 1/30 s slot, frame count equals length x 30 | tool |
| A5 | Pixel format | yuv420p, progressive | tool |
| A6 | Audio codec | AAC, 48 kHz | tool |
| A7 | Faststart | the index (`moov`) stands before the data (`mdat`), so playback can start while the file loads | tool |
| A8 | Audio stream is intact | the whole audio stream decodes with no error line | tool |
| A9 | Video stream is intact | every packet can be read and the key frames decode with no error line; with `--deep`, every frame | tool |
| A10 | Picture and sound equally long | difference at most 0.1 s | tool |
| A11 | Length is the planned length | file length equals `seconds` in `.build.json` within 0.1 s | tool |
| A12 | Colour tags | colour space BT.709, limited range (warning if missing: players then guess) | tool |
| A13 | The file plays in a real player | opens in QuickTime Player and in a browser, and seeking to the middle works | eyes |

## B. Audio

| # | What is checked | Passes when | Who |
|---|---|---|---|
| B1 | Integrated loudness | the builder's own target (-16 LUFS, read from `loudnorm()` in `tools/video_build.py`) within 1 LU | tool |
| B2 | True peak | at most -1.0 dBTP | tool |
| B3 | Clipping | sample peak below -0.1 dBFS, true peak below 0 dBTP, no flat tops | tool |
| B4 | Silence | every silence of 1 s or more is explained by the storyboard (the lead-in picture, a title or section card, a `[PAUSE]`, a scene step without narration). Unexplained silence above 2.5 s is a warning, above 6 s a failure; both are listed with their times | tool |
| B5 | The voice is intelligible and natural throughout | no garbled word, no robotic stretch, no sentence that stops in the middle, no word said twice | ears |
| B6 | Pronunciation of commands and names | `git reflog`, option names, file names and IDs are said the way `video/NARRATION_STYLE.md` ("How symbols are spoken") lays down | ears |
| B7 | Cuts | no click, no breath cut in half, no jump in level or tone between two paragraphs | ears |
| B8 | Reveal sounds | the pop, tick and whoosh stay far below the voice and never cover a word | ears |

Listening cannot be automated here. B5 to B8 need a person for the whole video, or at least: the first minute, the last minute, every beat the tool lists under C1, and three places chosen at random.

## C. Narration against picture (sync and alignment)

| # | What is checked | Passes when | Who |
|---|---|---|---|
| C1 | Pace of every narration beat | 1.51 to 4.54 words per second (0.55 to 1.65 times the configured 165 words per minute) and 8 to 19 letters per second, for beats of 8 words or more; a shorter beat must stay between 4 and 38 letters per second and under 10 words per second. A beat outside is listed with its sentence: too fast usually means the clip is cut short, too slow that silence was added | tool |
| C2 | Every voice clip is a verified one | each clip the video used has its `.ok` mark in `video/production/.cache/tts/`, the mark is older than the build, the clip itself is inside the pace bounds of C1, no beat fails C1, and each beat in the video is as long as its cached clips (within 0.06 s). N/A if the cache has been deleted; warning for single clips that left the cache | tool |
| C3 | Text given to the voice | the builder's own `spoken_chunks()` over the storyboard contains no raw code symbol (the builder's `RAW_SYMBOL` list) and no emoji | tool |
| C4 | The sound follows the beat timeline | beat starts ascend from 1.0 s, and every hold of 1.5 s or more is silent for at least 80 % of its length. If the sound were shifted against the picture, the holds would not be silent | tool |
| C5 | Spoken text unchanged since the build | the record of what was sent to the voice (`.cache/tts/VNNN.spoken.txt`) equals what would be sent today. N/A if the record is from another build | tool |
| C6 | The picture changes with the sentence that talks about it | at five places (start, three in the middle, end): the slide, the terminal line or the scene step appears when its sentence starts, not a sentence early or late | eyes + ears |
| C7 | Typing and reveals keep up | no terminal still typing when the narration has moved on; no bullet that appears after it was read | eyes + ears |

C1 and C2 are measured two ways on purpose. The `.ok` mark means that two attempts of the synthesiser agreed in length; it does not prove that the sentence is complete (two attempts can be cut short at the same place). The pace check catches that case. Since 2026-10-07 the builder applies the same pace bounds (`pace_fault()` in `tools/video_build.py`, which this tool uses for C1) before it marks a clip, so a clip that fails C1 can no longer be marked; C2 still fails any marked clip outside the bounds and any beat that fails C1. Neither replaces B5.

## D. Picture and layout

| # | What is checked | Passes when | Who |
|---|---|---|---|
| D1 | Black frames | `blackdetect` finds no black stretch of 0.5 s or more. By default only key frames are examined (at most 5 s apart); `--deep` examines every frame | tool |
| D2 | Blank frames | one frame every 30 s is sampled; each has at least 1 % edge pixels (a flat colour or a bare gradient has none; the least detailed sampled frame of each of the 43 videos checked measured 2.8 % to 5.9 %) | tool |
| D3 | Nothing is cut off or overlaps | no text outside the frame, no label over a commit, no line through a word; the mascot covers no content | eyes |
| D4 | Text is readable | the smallest text on any slide can be read at 720p in a normal player window | eyes |
| D5 | Spelling and code on screen | commands, flags, file names and IDs on screen are character for character those of the script | eyes |
| D6 | Motion | no flash, no jump between two pictures, no scene that plays too fast to follow, no frozen picture where the script describes movement | eyes |
| D7 | No draft stamp | "DRAFT VOICE" appears nowhere | eyes |
| D8 | Consistent look | palette and fonts are those of the course part; the title card matches the thumbnail | eyes |

The tool samples about one frame in 900. D2 finds a slide that failed to draw, not a slide that is wrong.

## E. Subtitles

| # | What is checked | Passes when | Who |
|---|---|---|---|
| E1 | The `.srt` parses | every block has a number, a time line and text; numbers run 1, 2, 3; the count equals the builder's | tool |
| E2 | Order | cues ascend and do not overlap | tool |
| E3 | Inside the video | first cue at 0 or later; last cue ends at most 0.5 s after the video | tool |
| E4 | No empty cue | every cue has text | tool |
| E5 | Line length | at most two lines of at most 42 characters (warning) | tool |
| E6 | Reading speed | at most 20 characters per second (warning) | tool |
| E7 | No markup | no `[ANIMATION]`, `[PAUSE]` or other direction in capitals in square brackets, no bold marker `**`, no backtick, no HTML tag | tool |
| E8 | Coverage | 100 % of the storyboard's narration is found in the cue text, beat by beat and in order (the percentage is reported) | tool |
| E9 | Cues appear with the words | at five places the cue on screen is the sentence being spoken, within about half a second | eyes + ears |

Cue times are spread over a beat in proportion to the text, not taken from the sound. E2 to E6 therefore also react to a faulty voice clip: a beat that is far too short makes its cues too fast, and can make them overlap.

## F. Chapters and metadata

The chapter rules are YouTube's (YouTube Help, video chapters).

| # | What is checked | Passes when | Who |
|---|---|---|---|
| F1 | First chapter | the first line of `.chapters.txt` starts at 0:00; every line is `M:SS Title`; the count equals the builder's | tool |
| F2 | Number of chapters | at least three | tool |
| F3 | Order | ascending | tool |
| F4 | Length | every chapter, the last one included, is at least 10 s long | tool |
| F5 | End | the last chapter starts before the video ends | tool |
| F6 | Titles | not empty, under 100 characters | tool |
| F7 | Title and description | `video/youtube-metadata.md` has an entry for the video; title 1 to 100 characters; description, with the chapter list pasted below it, at most 5000 characters | tool |
| F8 | No angle bracket | no `<` or `>` in title or description (warning) | tool |
| F9 | Chapter times land on the section cards | clicking each chapter in the player lands on the card of that section | eyes |
| F10 | Title, description and video say the same | the title names what the video teaches; the description promises nothing the video does not deliver | eyes |

## G. Thumbnail

| # | What is checked | Passes when | Who |
|---|---|---|---|
| G1 | Exists, right format | `video/thumbnails/VNNN.png` (or `.jpg`) exists and really is a PNG or JPEG | tool |
| G2 | Size | 1280x720 | tool |
| G3 | Weight | under 2 MB | tool |
| G4 | Readable when small | the words can be read at the size of a search result (about 320 pixels wide) | eyes |
| G5 | Belongs to this video | number, title words and part colour are those of this video | eyes |

## H. Teaching accuracy rules of this course

None of these can be measured. A person checks them with the script open beside the video.

| # | What is checked | Passes when | Who |
|---|---|---|---|
| H1 | No fact on screen that the script does not state | every command, number, ID, file name, label and caption in a slide or scene is in the script; an animation shows no step, branch or commit the script does not name | eyes |
| H2 | Caveats are kept | every caveat, every "Unverified" note and every risk label (SAFE, CAUTION, DANGEROUS) of the script is in the narration, and the risk label is on screen with its command | eyes + ears |
| H3 | No answer before its question | at every "predict", "pause and answer" and interview question, the answer is neither visible nor spoken until the question has been asked and the pause has passed. Look at the frames **before** the pause, including the scene behind it | eyes + ears |
| H4 | Incident causes are not revealed early | in an incident or debugging video, no slide, scene, caption, chapter title, thumbnail or description names the root cause before the script reaches it | eyes |
| H5 | An analogy comes with the place where it breaks | where the script gives a limit of an analogy, the video keeps it | ears |
| H6 | Transcripts match the labs | terminal output on screen is the output the script quotes, not a paraphrase | eyes |

The tool supports H only indirectly: I2 and I3 prove that the video was built from the script as it is now, E8 that the subtitles carry the whole narration, I4 that the storyboard tool raised no warning about a scene tag.

## I. Build record and upload record

| # | What is checked | Passes when | Who |
|---|---|---|---|
| I1 | The build report belongs to this MP4 | size in bytes as recorded; `.build.json` written 0 to 180 s after the MP4; the builder's own checks passed | tool |
| I2 | Built from the current script | the script SHA-1 in `.build.json` equals the script on disk | tool |
| I3 | The storyboard is the one for this script | storyboard, script on disk and `.build.json` name the same script SHA-1 (warning if the storyboard file is newer than the build) | tool |
| I4 | Storyboard is clean | no warnings and no hints | tool |
| I5 | Animated | built with the animation layer | tool |
| I6 | Voice from after the voice fix | the build started after the builder's voice check went in (2026-10-07 08:09:33, the modification time of `tools/video_build.py` recorded in `VOICE_FIX_EPOCH`). Older: "narration from before the voice fix" | tool |
| I7 | The file did not change during the check | same size and time before and after (only reported when it fails) | tool |
| I8 | The uploaded file is the checked file | the SHA-256 in `out/qc/VNNN.qc.json` equals that of the file that was uploaded; QC was run after the last build, not before | eyes |
| I9 | Upload record is complete | the upload log names the video, the `.srt` and the `.chapters.txt`; the release or video URL is noted | eyes |
| I10 | After upload | on YouTube: processing finished in HD, the chapters show on the timeline, the subtitles are attached as English, the thumbnail is the custom one, title and description are those of `youtube-metadata.md` | eyes |

## Thresholds

Every number is a constant at the top of `tools/video_qc.py`, with its reason. Those that are a matter of judgment started strict and were changed only for a stated reason:

| Threshold | Started at | Now | Reason |
|---|---|---|---|
| Frame timing (A4) | exact | within 1 ms | The builder joins separately encoded segments; at a join a frame is 0.3 to 0.7 ms early (10 of 33,981 frames in V001). Far below one frame (33 ms). |
| Pace (C1) | 0.70 to 1.30 times the rate | 0.55 to 1.65 times, plus 8 to 19 letters per second | On 423 verified clips the pace runs from 1.65 words/s ("Read sections 26.6 to 26.9 of Chapter 26") to 4.44 ("And the start that is the wrong way round"): word length decides. Letters per second vary less (9.0 to 16.2), so both are checked. Faulty clips lie far outside (5.6 and more, 1.2 and less). Short beats (under 8 words) had no lower bound at first; 4 letters per second was added because a 7-word sentence that lasts 19 s in eighteen older videos went unreported. |
| `**` in subtitles (E7) | any two stars | two stars that open or close a word | The narration of V087 names the glob pattern `docs/**`. |
| ffmpeg time limit | 100 s, once | 110 s, then a second try with 220 s | With three builds running, one audio pass ran out of time. A pass that does not finish is reported as "not measured", never as PASS. |

Not changed although it is close: the true peak limit (B2). Healthy builds measure -1.0 to -1.3 dBTP against a limit of -1.0, because the builder limits the uncompressed sound to -1.5 and the AAC encoder adds a little. A healthy video can land at -0.9 one day; the right fix is then a lower target in the builder, not a looser limit here. Since 2026-10-07 the builder measures the finished, AAC-encoded track and limits it to -1.5 dBTP or below (`seal_audio()`; three tracks measured -2.0 dBTP at -16.1 LUFS); videos built before that keep their -1.0 to -1.3.

## What the tool cannot check

- How the voice sounds: pronunciation, a garbled word, a sentence cut off at a natural pause, tone. (B5 to B8)
- Whether a slide or scene is correct, readable and free of overlaps. It samples one frame every 30 s and only asks "is there anything on it". (D3 to D8)
- Whether picture and sentence belong together. C4 proves that the sound is not shifted against the timeline, not that the right picture is on screen. (C6, C7, E9)
- All of section H.
- Black or broken frames between key frames, unless `--deep` is used.
- Anything about the uploaded copy on YouTube. (I8 to I10)
- Videos narrated by a recorded person: C2, C5 and I6 are N/A, and the pace bounds are wide (1.2 to 4.5 words per second).
