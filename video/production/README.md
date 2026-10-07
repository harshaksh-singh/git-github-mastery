# Recording the course videos: a guide for the narrator

You record your voice. Everything else is automatic: the slides, the timing, the cuts, the sound level, the subtitles, the chapter list and the finished MP4 file.

You do not need to know Git, video editing or programming to use this guide. You type a few commands in the Terminal app and press a few keys in Google Chrome.

## 1. What you need

Everything is already on this Mac except one program.

| Needed | What for | How to check |
|---|---|---|
| Google Chrome | draws the slides and records your microphone | it is in the Applications folder |
| Python 3 | runs the tools | type `python3 --version` in Terminal |
| Node | makes drawing the slides fast (optional: without it the tools still work, more slowly) | `node --version` |
| The macOS voice "Samantha" | speaks the preview ("draft") videos | `say -v Samantha hello` |
| **ffmpeg** | writes the MP4 file | `ffmpeg -version` |

If `ffmpeg -version` answers "command not found", install it once with Homebrew:

```bash
brew install ffmpeg
```

Nothing else has to be installed. The tools use no extra Python or Node packages.

A microphone: a USB microphone or a headset is much better than the microphone built into the laptop.

## 2. The commands

Open the Terminal app. Go to the course folder once (drag the folder onto the Terminal window after typing `cd ` and a space, then press Return). After that every command below starts with `video/production/make.sh`.

| Command | What it does |
|---|---|
| `video/production/make.sh status` | A table of all videos: script, storyboard, slides, recording, draft, finished video |
| `video/production/make.sh draft V008` | A preview of video 8 with the computer voice, so you can watch it before recording |
| `video/production/make.sh record V008` | Opens the recording booth for video 8 in Chrome |
| `video/production/make.sh build V008` | Turns your recording into the finished video |
| `video/production/make.sh build all` | Builds every video that has a recording and is not finished yet |
| `video/production/make.sh storyboard V008` | Reads the script again (only needed after a script was edited) |
| `video/production/make.sh slides V008` | Draws the slides again (only needed after a script was edited) |
| `video/production/make.sh selftest` | Checks the booth, the builder and the animation layer without a microphone |
| `video/production/make.sh animate V008` | Adds motion to video 8: typing terminals, lists and tables that reveal, animated diagrams, the mascot (section 12) |
| `video/production/make.sh voice V008` | A finished video narrated by the computer voice "Tara" instead of a recording |
| `video/production/make.sh demo` | A video of about twelve minutes that plays every animated scene of the library once |
| `video/production/make.sh qc V008` | Measures a finished video against `QC_CHECKLIST.md` (file, sound, voice clips, subtitles, chapters, thumbnail, build record). Reads only; the report is `out/qc/V008.qc.json`, the table `out/QC-SUMMARY.md` |

Instead of one number you can write several (`V008 V009`), a range (`V010-V020`) or `all`. `all` skips what is already up to date.

`record` and `build` prepare the storyboard and the slides by themselves, so for normal work you only need `record` and `build`.

A video that has been animated once (`animate V008`) stays animated: `build`, `draft` and `voice` use the animation whenever it exists and bring it up to date by themselves. Nothing changes for the narrator: the booth, the keys and the recordings are the same.

## 3. Recording one video, step by step

1. **Watch the draft first (optional but useful).** `video/production/make.sh draft V008`, then open `video/production/out/V008.draft.mp4`. You see every slide and hear the text in a computer voice. The draft has a "DRAFT VOICE" label in the corner so nobody uploads it by mistake.
2. **Start the booth.** `video/production/make.sh record V008`. Chrome opens a page at an address that starts with `http://localhost:`. Leave the Terminal window open; it is the program that saves your recording.
3. **Allow the microphone.** The first time, Chrome asks "localhost wants to use your microphone". Click **Allow**. macOS may ask as well: allow Google Chrome there too.
4. **Look at the page.**
   - Left: the list of sections. A green dot means recorded, yellow means partly recorded.
   - Middle: the slide the viewer sees, the level meter, and the buttons.
   - Right: the text to read now, in large type, and the next text below it in grey.
5. **Click "Start recording".** A countdown 3, 2, 1 appears. Then the first card is shown.
6. **Read.** Read the large text aloud. When you have finished the paragraph, press **Space** (or **Right Arrow**). The next text and its slide appear. Read on.
   - Some steps are silent: the title card, the card at the start of each section, and the pauses the script asks for. The page says "stay silent" and moves on by itself after a few seconds (up to twelve for a large drawing that nothing is read over). Use them to breathe.
   - Text in a grey box, like `git status`, is a command or a file name. Read it as you would say it to a colleague: "git status".
   - Do not read the coloured circle of a risk label; read the word after it ("safe", "caution", "dangerous").
7. **If you make a mistake**, press **Left Arrow** (or **Backspace**) and read the same text again from its first word. See section 5.
8. **If you need a break**, press **P**. Press **P** again to go on; the current text starts again from its first word.
9. **At the end** the booth saves by itself. You can also click **Finish** at any moment to stop early: what you have read so far is saved, and you can record the rest later (section 6).
10. Wait for the green message "Saved". Then go back to the Terminal, press **Ctrl+C** to stop the booth, and build the video (section 7).

Keys, all in one place:

| Key | Effect |
|---|---|
| Space or Right Arrow | This text is done; show the next one |
| Left Arrow or Backspace | Say this text again (the failed attempt is cut out) |
| Up Arrow | Go back one text and say that one again |
| P | Pause / continue |
| Finish (button) | Stop and save |

## 4. Microphone tips

- Record in a small room with soft things in it: curtains, a carpet, a sofa. An empty room with hard walls echoes.
- Keep the microphone a hand's width from your mouth, a little to the side, so that "p" and "b" do not pop.
- Watch the level meter while you speak a test sentence. The bar should move through the green part and touch yellow on loud words. If the page says "too loud", move back or turn the microphone down in System Settings > Sound > Input. If the bar hardly moves, come closer.
- Keep the same distance for the whole video. The builder evens out the overall loudness (to about -16 LUFS, the usual level for online video), but it cannot repair a voice that is far away in one paragraph and close in the next.
- Close the door and the window, switch off fans, put the phone on silent.
- Press the keys gently, and press Space only after the last word has ended. The cut is made at the moment you press the key.
- Drink water. Record at most two or three videos in one sitting; a tired voice is audible.

## 5. How retakes work

The booth records one continuous sound file and writes down the exact moment of every key press. Nothing is deleted while you record.

- You read text 12, stumble, press **Left Arrow**, and read text 12 again correctly, then press **Space**. The builder keeps only the stretch between the Left Arrow and the Space. The stumble is cut out.
- You may press Left Arrow as often as you like. Only the last attempt is kept.
- You pressed Space and then notice that the previous text was not good: press **Up Arrow**. The booth goes back one text; read it again and press Space. The newer attempt replaces the older one.
- On a silent card, Left Arrow takes you back to the text you read just before it.
- A pause (**P**) throws away the attempt that was in progress; after you continue, read the text from its first word.
- The slide on screen is always shown for exactly as long as you spoke over it. If you read slowly, the video is slower; nothing has to be adjusted by hand.

The original sound files are never changed. They stay in `video/production/recordings/`, so a video can be rebuilt at any time.

## 6. Stopping and continuing later

You do not have to record a video in one go.

- Click **Finish** when you want to stop. The booth says how many texts are still missing.
- Later, start the booth again (`video/production/make.sh record V008`). The section list shows what is recorded. The first section that is not complete is already selected. Click **Start recording** and continue.
- To record one section again, for example because the script changed or you did not like it, click that section in the list, click **Start recording**, read to the end of the section and click **Finish**. For every text, the newest recording is used.
- To throw everything away and begin again: `python3 tools/video_booth.py V008 --reset`. The old files are not deleted; they are moved to `video/production/recordings/archive/`.

If a script is edited after you recorded it, only the changed paragraphs have to be read again. The booth marks those sections yellow, and `build` tells you which texts are missing.

## 7. Building the finished video

```bash
video/production/make.sh build V008
```

The builder
1. cuts the retakes, pauses and the countdown out of your recording,
2. shows each slide for exactly the time you spent on its text, with clean cuts between slides (in an animated video: with a short crossfade, and with the slide's animation starting when you start reading its text),
3. puts the thumbnail in front as the first second,
4. brings the sound to the standard loudness,
5. writes the video, the subtitles and the chapter list,
6. checks the result: size 1920x1080, 30 pictures per second, picture and sound equally long.

The last line it prints ends with `OK`. If it ends with `CHECK FAILED`, do not upload; see section 10.

If some texts are not recorded yet, the builder stops and names the sections. Record them (section 6) and build again.

## 8. Where the files are

| Folder or file | Content |
|---|---|
| `video/scripts/V008-....md` | the script (do not edit while recording) |
| `video/production/storyboards/V008.json` | the script cut into "beats": one text plus the slide shown with it |
| `video/production/slides/V008/001.png ...` | the slides, 1920x1080 |
| `video/production/recordings/V008.webm` | your first take |
| `video/production/recordings/V008.take02.webm ...` | later takes (sections recorded again or later) |
| `video/production/recordings/V008.timing.json` | the moments of your key presses |
| `video/production/out/V008.mp4` | **the finished video** |
| `video/production/out/V008.srt` | subtitles |
| `video/production/out/V008.chapters.txt` | chapter list for the YouTube description |
| `video/production/out/V008.build.json` | the builder's report: length, checks |
| `video/production/out/V008.draft.mp4` | the computer-voice preview, never for upload |
| `video/production/anim/V008/` | the animation of video 8, if it has one: `anim.json` and short clips in `clips/` (made again from the script at any time) |
| `video/production/ANIMATION_STYLE.md` | the animation style, the mascot, and the `[ANIMATION]` tags a script may use |
| `video/production/booth/` | the booth page (`booth.html`, `booth.css`, `booth.js`) and the generated page per video in `pages/` |
| `video/production/.cache/` | working files; can be deleted at any time |

Back up `video/production/recordings/`. Everything else can be made again from the scripts and the recordings.

## 9. Uploading to YouTube

For each video you need four things:

1. **The video file:** `video/production/out/V008.mp4` (never the `.draft.mp4`).
2. **Title and description:** copy them from the entry for V008 in `video/youtube-metadata.md`.
3. **Chapters:** open `video/production/out/V008.chapters.txt`, copy all lines, and paste them into the description, below the text. The first line must stay `0:00 ...`; YouTube then shows the chapters on the timeline. (Sections shorter than ten seconds are joined to the one before them, because YouTube does not accept shorter chapters.)
4. **Thumbnail:** `video/thumbnails/V008.png`. In YouTube Studio: Details > Thumbnail > Upload file.

Optional: subtitles. In YouTube Studio: Subtitles > Add language > English > Upload file > "With timing", and choose `video/production/out/V008.srt`. The subtitles are the script text, so they are correct where automatic captions get command names wrong.

Before you publish, play the first and the last minute, and click through the chapters once.

## 10. Troubleshooting

| What you see | What to do |
|---|---|
| `ffmpeg is not installed` | Run `brew install ffmpeg`, then the same command again. |
| Chrome does not ask for the microphone, and the page says "The microphone is not available" | Click the icon left of the address in Chrome's address bar, set Microphone to Allow, reload the page. In macOS: System Settings > Privacy & Security > Microphone > switch on Google Chrome, then quit and reopen Chrome. |
| The level meter does not move | The wrong microphone is selected. Chrome: Settings > Privacy and security > Site settings > Microphone, choose your microphone. macOS: System Settings > Sound > Input. |
| The page opened in Safari | Copy the address (`http://localhost:8765/`) into Google Chrome. |
| "Saving failed" in red | The booth program in the Terminal was closed. The page offers two download links: download both files. Start the booth again and tell the person who maintains the tools; the two files contain your complete take and can be put in place by hand (rename them to `V008.webm` and add the take to `V008.timing.json`). |
| The address shows a different number, for example `localhost:8766` | Normal: port 8765 was busy, the next free one was taken. |
| You closed the Chrome tab while recording | That take is lost. The takes saved earlier are safe. Start the booth again and continue with the first yellow or empty section. |
| `beat(s) are not recorded yet` when building | Start the booth, record the sections it names, build again. To see the video anyway, with silence where texts are missing: `python3 tools/video_build.py V008 --allow-missing`. |
| `the script changed after beats ... were recorded` | The script was edited. Read those texts again (section 6). |
| The video ends with `CHECK FAILED` | Run the same build command with `--force`. If it fails again, send `video/production/out/V008.build.json` to the maintainer. |
| A slide looks wrong (text cut off, wrong table) | Note the video number and the time. The maintainer can open the slide's page in `video/production/.cache/html/V008/` and correct the tools; then `make.sh slides V008` and `make.sh build V008` again. Your recording stays valid. |
| The draft voice mispronounces commands | That is expected; drafts are only for checking slides and length. |
| An animated video looks wrong in one place (a label over a commit, a terminal typing too fast) | Note the video number and the time for the maintainer. To get the video without motion meanwhile: `python3 tools/video_build.py V008 --no-anim`, or remove the animation for good with `video/production/make.sh animate --off V008`. |
| `the animation is incomplete ... building with still slides instead` | Some clips could not be drawn. The video is still correct, only without motion. Run `video/production/make.sh animate V008` and send the lines it prints to the maintainer. |
| The computer voice reads a command oddly ("dash dash", "dot git") | Intended: commands are spelled the way a person would say them. The table is in `tools/video_build.py` (`speakable`). The exact text sent to the voice for the last build is in `video/production/.cache/tts/V008.spoken.txt`. |
| You want to be sure everything works before a long session | `video/production/make.sh selftest`. It ends with "0 failed" when the booth and the builder work. It uses a generated tone, not your microphone, so also do a ten-second real test: start a recording, read two texts, click Finish, run `build` with `--allow-missing`, and listen. |

## 11. For the maintainer: how it fits together

| Tool | Reads | Writes |
|---|---|---|
| `tools/video_storyboard.py` | `video/scripts/VNNN-*.md`, the textbook chapter for "the table of section N.M" | `storyboards/VNNN.json` |
| `tools/video_slides.py` (+ `tools/video_shoot.mjs`) | the storyboard, `video/thumbnails/VNNN.png` | `slides/VNNN/NNN.png`, `manifest.json` |
| `tools/video_booth.py` (+ `booth/booth.*`) | storyboard, slides | `recordings/VNNN*.webm`, `VNNN.timing.json` |
| `tools/video_build.py` | storyboard, slides, recordings | `out/VNNN.mp4`, `.srt`, `.chapters.txt`, `.build.json` |
| `tools/video_takes.py` | the key-press log | which stretch of which take belongs to which beat |
| `tools/video_status.py`, `tools/video_selftest.py` | | the status table, the self-test |

- A **beat** is one text the narrator reads, or a silent hold. A **slide** is one distinct picture. Several beats can share a slide.
- `python3 tools/video_storyboard.py --dump V008` prints every beat with its slide, its estimated time and, for a textbook table, the file and line it was taken from.
- Slides are redrawn only when their content changes (a content hash per slide is kept in `manifest.json`). When a thumbnail appears or changes, only the title slide is redrawn.
- The palette comes from the `PARTS` table in `tools/build_thumbnails.py`, so videos match their thumbnails.
- The booth server listens on 127.0.0.1 only and refuses requests that do not come from its own page.

## 12. The animation layer

Without animation, a video is a row of still slides with hard cuts. `video/production/make.sh animate V008` adds motion, and from then on every build of that video uses it:

- **Every slide moves in.** Terminals type their commands and scroll their output in; when a paragraph names several commands, each one is typed when it is named. Bullets and table rows arrive one at a time, with the beat that talks about them. Key points, callouts and section cards rise into place. Between pictures there is a short crossfade, and while a picture is held it drifts very slowly, so the frame is never frozen.
- **Commit graphs are replayed.** A drawing in a `text` fence that is an ASCII commit graph is turned into a real graph: commits appear in order, labels slide when a "Before / After" pair moves them, and the commit being named pulses. Drawings that are not understood keep their still picture and are drawn in line by line.
- **Explainer scenes.** A script line `**[ANIMATION]** rebase: feature onto main` plays a scene from the library: the eleven scenes of batch one (commit graph, merge, rebase, three trees, object model, content addressing, lab sandbox, remotes, reflog rescue, pull request, CI run), now with parameters for the commits, names and steps of the script at hand, and fourteen schematic and topic scenes added for the later batches (a sequence between actors, gates on a line, layers that add up, a table walked row by row, patterns against paths, a decision tree or state diagram, boxes that hold things, bars, cards, blame, a rebase todo list, the anatomy of a push, the recovery ladder, a workflow run in detail), plus bisect, stash and tags drawn as commit graphs. In the platform scenes every label comes from the script. A scene is built up step by step under the paragraphs that follow it, can leave and come back later (`**[ANIMATION]** step: name`), and can replace an ASCII drawing. Scenes take parameters so that the picture shows the script's own branch names, file paths, commit IDs and counts (a merge with real IDs, a graph in several states whose labels slide, a pull request that is blocked, a clone and its server without a teammate), and every caption and command line can be reworded or hidden per step. The tags, their steps and their parameters are listed in `ANIMATION_STYLE.md`; V001, V007 and V030 use them. Scripts without tags work exactly as before.
- **Key points** (a single sentence on screen) get one of four layouts: a statement with a small animated drawing, a centred question, a two-card contrast, or a big number. Key terms are coloured and underlined. This redesign exists only in animated videos; the still slides and the booth are unchanged.
- **Twig**, the mascot, stands in the bottom-right corner, blinks, and reacts: thinking at a pause or a question, worried at a red risk label and for the few seconds a destructive scene step plays, celebrating at the recap; and, only where a script asks for it, pointing at a spot of a scene, nodding, or asking for care.
- **Sound.** Three quiet synthesised sounds (a pop, a key tick, a soft whoosh), far below the voice. No music.

| Tool | Reads | Writes |
|---|---|---|
| `tools/video_animplan.py` | the storyboard being built | the plan inside the storyboard: per beat, a list of cues (what moves, and where in the paragraph), the mascot's pose |
| `tools/video_animate.py` (+ `tools/video_animshoot.mjs`, `tools/anim/*.js`) | the storyboard | `anim/VNNN/anim.json`, `anim/VNNN/clips/*.mp4` |
| `tools/video_build.py` | the clips, the narration | the MP4: every cue becomes "its clip, then its last frame held" |
| `tools/video_animtest.py` | the demo script (its tags are the test samples), `tools/anim/compat/` | section 6 of the self-test; `--look 'tag'` renders one tag with a layout check and a contact sheet; `--compat` compares planner, pictures and motion with the library as it was when batch one was approved |

- A **cue** is one animation: it has a clip of 0.2 to about 4 seconds, rendered once. Only the moving part is rendered in Chrome; the hold that follows is the clip's last frame, zoomed by ffmpeg. Clips are named by a hash of their page, so after a script edit only the changed ones are rendered again.
- Rendering does not use the clock. `tools/video_animshoot.mjs` asks the page for the frame at time `i / 30`, takes a screenshot, and goes on to the next frame; the same page always gives the same frames.
- Cues are placed in time when the video is built, because only then is the length of each paragraph known: a cue "at 0.4" starts 40 % into its paragraph. A clip that would not fit before the next cue is played faster, never cut.
- Cost on this Mac (M1 Pro, measured on V001, V007 and V030, 15 to 19 minutes each, with explainer scenes): 63 to 72 seconds to render the clips (94 to 98 clips, 3,900 to 4,600 frames), about 25 MB of clips per video, and 153 to 174 seconds to build the MP4 once the voice is cached (about a minute more the first time, while the computer voice speaks the text). The MP4 is larger than the still-slide version because the picture never stands still: 90 MB instead of 52 MB for V001.
- Editing anything in `tools/anim/*.js` changes every clip (the scripts are part of each page), so the next build of an animated video renders all its clips again; editing a script renders only the clips of the changed beats. The scenes are in `scenes.js` (batch one, generalized), `scenes2.js` and `scenes3.js` (the schematic and topic scenes).
- After a change to the library, `python3 tools/video_animtest.py --compat pictures` and `--compat motion` prove that the videos already built would look the same: every scene picture of the storyboards frozen with batch one, and every frame of every scene clip of batch one and of the demo, is drawn by the frozen JavaScript (`tools/anim/compat/v1/`) and by the current one, and the frames must be identical byte for byte. A page that differs is rendered a second time before it counts (Chrome very rarely draws one frame with a pixel one grey level off).
- To look at the pages behind one beat in a browser: `python3 tools/video_animate.py --page V008 40` writes them to `video/production/.cache/anim-pages/V008/` and prints the paths. In the browser console, `__anim.seek(0.5)` shows the picture half a second in.
- `python3 tools/video_animate.py --plan V008` prints every beat with its cues without rendering anything.
