# Scene pass: brief for script editors (October 2026)

Every script has had its teaching pass (greeting, activities, pauses, definitions). The animation library has since been extended. Your pass places the pictures. Work only in `/Users/apple/git-mastery`, only on the scripts of your range, yourself (no sub-agents), one script completely before the next, saving as you go.

## Read first
1. `video/production/ANIMATION_STYLE.md` completely: section 0 (topic → scene), section 9 (graph notation), section 10 (every scene, parameters, steps, examples).
2. `authoring/VIDEO_DIRECTOR_BRIEF.md` and `video/NARRATION_STYLE.md` (the standard for narration, including the owner's brief).
3. `authoring/VIDEO_FIX_LIST.md`: close every item that names a script of your range, and say in your report how.
4. `authoring/scene-wishes/VNNN.md` if it exists for your script: the previous editor's list of wanted pictures. `authoring/ANIMATION_LIBRARY_GAPS.md` shows which earlier workarounds now have a proper form.
5. Two approved videos as the standard: scripts `video/scripts/V031-*.md` and `video/scripts/V024-*.md`.

## The job, per script
- **Aim: an explainer scene on screen for a quarter to a third of the running time**, and every core idea of the video has a picture that changes while the narration explains it (3Blue1Brown manner: one picture that evolves, not many that restart). Do not force a scene where a transcript, a table or a file listing is the right thing to look at.
- Prefer one scene carried through a section with `step:`, `say:` and later states over several separate scenes. Bring a scene back (`replay:`, `step: id.step`) in the mental model and the recap.
- **Accuracy rules.** A scene shows only what the script states: its own branch names, paths, commit IDs, counts, file names, job names. Use real IDs where a snippet of the same script prints them; letters only where it prints none. A parent link, a ref position or any other fact not printed in the script must be verified by replaying the lab in a sandbox (`labs/run`, with `GIT_MASTERY_LABS` pointed at your own scratchpad sub-folder) or left out. Use the right style for the right fact: `ghost:` unreachable, `reflog:` named only by a reflog, `absent:` not in this clone, `gone:` pruned, `dim:` not visited. GitHub and Actions pictures are schematic and carry only labels the script gives; never imitate GitHub's interface, never show as observed what the script marks as documented, unverified or announced, and keep every such caveat in the narration.
- **Incident and drill videos:** nothing on screen may reveal the cause before the script's reveal. Before the reveal show only the symptom.
- Replace an ASCII drawing by a scene only when the scene shows everything the drawing shows; otherwise keep the drawing and add the scene elsewhere.
- No quiz may be asked over a table or picture that shows its answer. No drawing or scene may be held in silence, and no caption may contradict the paragraph being read (`say:` or `captions=off`).
- **What you may change:** `**[ANIMATION]**` and `**[PAUSE]**` lines, and narration paragraphs only as far as needed to match the picture ("on the left", "watch the label slide") or to close a fix-list item. Narration may not grow by more than 3 percent in this pass. Do not touch snippets, transcripts, YAML, tables, headings or on-screen directions, except where a fix-list item says a direction is wrong. Add no new facts.
- Check every new tag: `python3 tools/video_animtest.py --look '<tag>' --name <yourprefix>-x` (layout check of every state and a contact sheet; look at the sheet with your image reader for overlaps, tiny text, labels crossing edges, wrong order). Then `video/production/make.sh storyboard VNNN` must give no warnings, and `python3 tools/inject.py --check` and `python3 tools/check_course.py` must report no problem.
- Do not build videos (`make.sh animate`, `voice`): a build queue runs separately and the machine cannot take parallel renders. Never run anything against GitHub; `gh` only with `--help`. Do not touch `video/production/recordings/`, the library (`tools/`), or scripts outside your range. If the library lacks something, do the best with what exists and report it; do not edit the library.
- The scratchpad is shared: create your own sub-folder first, keep every helper and lab root in it, never delete or overwrite what you did not create. One shell command may run at most ten minutes.

## Report
Concise: per script, the scenes placed (count and kind), the estimated scene share from the storyboard, fix-list items closed, facts verified in the sandbox, anything left imperfect or that you could not draw, and confirmation of the checks.
