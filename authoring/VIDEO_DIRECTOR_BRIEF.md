# Brief for director-editors: narration voice and animation for a range of videos

You take finished, technically exact video scripts and make them (1) sound like a kind, brilliant teacher talking to a newcomer and (2) come alive on screen with the animation library. Three pilot videos already show the target: V001, V007 and V030. Work only in `/Users/apple/git-mastery`.

## Read first
1. `video/NARRATION_STYLE.md` — the voice, including the section "Owner's brief", which has priority.
2. `video/production/ANIMATION_STYLE.md` — the animation tags (`**[ANIMATION]** scene: ...`, `step:`, `end`), the scenes, their parameters and steps.
3. The three pilot scripts `video/scripts/V001-*.md`, `V007-*.md`, `V030-*.md` next to their originals in `video/scripts-original/` (diff them) to see exactly what a finished script looks like.
4. `authoring/VIDEO_SCRIPT_BRIEF.md` for the script format.

## For each script in your range, in order
1. Copy the current file to `video/scripts-original/` if it is not there yet.
2. **Rewrite the narration paragraphs** in the series voice. Rules: every technical fact, command, flag, number, version, caveat and "Unverified" note stays exactly as accurate; no new technical claims; headings, header block, fenced blocks and snippet blocks stay byte for byte; narration length within about 15 percent of the original. Define each term in one plain sentence the first time it appears in the video. Write for a text-to-speech voice (no parentheses, slashes or symbols in narration; the pronunciation of code spans is handled by the builder).
3. **Add interaction.** At least three viewer activities per video, each followed by a `**[PAUSE]**` line: a prediction before a demo step, a two-or-three-option quiz, and a thirty-second "try it now". Give and explain the answer after the pause.
4. **Direct the animation.** Add `**[ANIMATION]**` lines wherever the narration explains something a library scene shows (commit graph, fast-forward and merge, rebase, three trees, object model, remotes, reflog rescue, pull request, CI run, sandbox, hash), with parameters that match the script's own branch names, file names and commit IDs, and `step:` lines so the picture changes with the paragraph that describes the change. Use only scenes, parameters and steps that `ANIMATION_STYLE.md` documents. A scene placed before an ASCII diagram replaces that drawing; do this only when the scene shows the same thing. Aim for an explainer scene or animated diagram on screen for at least a fifth of the video where the topic allows; do not force a scene that does not fit.
5. You may add or move `**[PAUSE]**` and `**[ANIMATION]**` lines. Do not change other stage directions.
6. Check the script: `python3 tools/inject.py --check <file>` and `python3 tools/check_course.py <file>` report no problems; `python3 tools/video_storyboard.py <VNNN>` builds without warnings about unknown tags (fix the tag, not the tool); a diff against the original shows changes only in narration paragraphs and in `[PAUSE]`/`[ANIMATION]` lines.
7. Save the script before starting the next one. You may be interrupted; begin by checking which scripts in your range already have a copy in `video/scripts-original/` and look finished, and continue from the first that is not.

## Do not
- Do not build videos (`make.sh voice`), render slides or run the animation renderer; a separate step does that.
- Do not edit tools, the textbook, thumbnails, other ranges' scripts, or anything in `video/production/recordings/`.
- Do not launch sub-agents.

## Report
Scripts finished, narration word counts before and after in total, how many `[ANIMATION]` and `[PAUSE]` lines were added, any script where no scene fit and why, any storyboard warning you could not resolve, and anything you were unsure about.
