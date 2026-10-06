# Brief for video script writers

You write the scripts for one batch of videos of the Git and GitHub Deep Mastery course. The written course is finished and is the only source of truth.

## Inputs

1. `authoring/STYLE_GUIDE.md` — read sections 1, 2, 4, 9 and 12 (audience, accuracy protocol, labels, terminology, lab clock).
2. `video/video-curriculum.md` — section (a) for the production conventions, then the entries of your videos. Each entry fixes the title, objectives, prerequisites, concepts, commands, demonstration scripts, diagrams, exercise, challenge, interview question, homework and expected outcome. Follow it.
3. `video/script-batches.md` — your batch, its chapters and demo directories.
4. For each video: the textbook sections its entry cites (read them in full before writing; they are the authority, and where the curriculum entry and the textbook differ, the textbook wins and you note it in your report), and the transcripts of its demo scripts in `labs/<dir>/out/<name>/*.txt`.

## Output

One file per video: `video/scripts/VNNN-<slug>.md` (slug from the title, lower case, hyphens). Write them in order and save each one before starting the next; first check which already exist and keep them.

Each script has exactly these thirteen `##` sections, in this order:

HOOK · INTRODUCTION · LEARNING OBJECTIVES · CONCEPT · MENTAL MODEL · DIAGRAM · LIVE TERMINAL DEMO · COMMON MISTAKES · PRODUCTION EXAMPLE · PRACTICE EXERCISE · INTERVIEW QUESTION · RECAP · HOMEWORK

Above them: the `# VNNN: Title` heading and a short header block (part, module, planned minutes, prerequisites, textbook sections, demo scripts).

## How to write each section

- **Spoken narration is written out in full**, as the presenter will say it, in plain second-person sentences. Mark stage directions in bold at the start of a paragraph: **[ON SCREEN]**, **[TERMINAL]**, **[DIAGRAM]**, **[PAUSE]**. A 20-minute video needs roughly 2,200 to 2,800 words of narration; scale with the planned minutes.
- **HOOK**: a production question or failure in 30 to 60 seconds, taken from the textbook section's "Why this matters" or "In production" material. No hype.
- **CONCEPT** then **MENTAL MODEL**: follow the course order why, what, how, internals, when, when not, failure modes, recovery. Use the textbook's own analogy and say where it breaks.
- **DIAGRAM**: the ASCII diagram from the cited textbook section, reproduced in a `text` block, with the narration that builds it step by step.
- **LIVE TERMINAL DEMO**: the presenter runs the named demo scripts' commands by hand in `labs/shell`, or replays them with `labs/run <dir>/<name>`. Show commands in `bash` blocks, one step at a time, and for each step say what to predict before running and what to point at in the output. Do not paste transcripts: place the output through snippet markers exactly as the textbook does (`<!-- snippet: <dir>/<demo>/<name> -->` followed by an empty `text` fence and `<!-- /snippet -->`), choosing only the snippets the video needs, then run `python3 tools/inject.py <your files>`. Never type output or object IDs by hand; an ID mentioned in narration must appear in an injected snippet of the same script. GitHub-side demos are screen walkthroughs of the learner's own practice repository following the named lab: describe what to click and what the documentation says will appear, say that the interface changes, and show no captured GitHub output.
- **COMMON MISTAKES**: three to five, each with the root cause in one sentence, from the section's "What can go wrong" table or root-cause boxes.
- **PRODUCTION EXAMPLE**: one realistic case from a backend or AI/ML team, consistent with the textbook's examples.
- **PRACTICE EXERCISE**: the lab or exercise named in the curriculum entry, with what the learner must predict first. No answers.
- **INTERVIEW QUESTION**: the bank question quoted with its number, then guidance on what a strong answer covers (the model answer itself stays in the answers file; do not reproduce it).
- **RECAP**: three to five sentences the learner should now be able to say.
- **HOMEWORK**: from the curriculum entry.
- Risk labels 🟢 🟡 🔴 are spoken and shown the first time a state-changing command appears, with the label the textbook's "Command safety" table gives.

## Rules

- Introduce no command, flag, fact, version, date, GitHub feature or statistic that the cited textbook sections do not contain. Keep every "Unverified" and version caveat the textbook attaches to a fact.
- Do the work yourself without launching sub-agents.
- Do not change any file outside `video/scripts/`.
- Finish with `python3 tools/inject.py --check <your files>` and `python3 tools/check_course.py <your files>` reporting no problems, a check that every file has the thirteen sections in order, and a short report: scripts written, total words, any place where the curriculum entry had to be corrected against the textbook, and anything you could not verify.
