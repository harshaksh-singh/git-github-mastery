# Video fix list (open items reported by script editors; for the scene pass and the build inspectors)

Each item is closed by the scene-pass editor of that range, who notes the outcome in the batch report.

## Batch 2 and 3 (V034 to V099)
- V075, V076: verify what `ORIG_HEAD` holds after the second reset (sandbox), then draw it.
- V090, V094: parent links in graphs were inferred; verify in the sandbox.
- V041: the placeholder label `yours` in a scene; replace with the script's own name.
- V037 line 232: "2048." rendering in narration.
- Contraction passes were scripted: spot-check subtitles.

## Batch 4 (V100 to V133)
- V105: graph parent links taken from V100/V101 (same repository): verify. V110: tag `schemas/v1.1.0` on `100bb99` inferred: verify. V113: HEAD on `main` in `orbit`; V117: chain bf7889c → c7182c9 → 39c4105 and branch `main`: verify against the lab fixtures.
- V103, V109: ghost style was used for "reachable only through the reflog" and "behind a shallow boundary"; switch to the new distinct styles.
- V108 "try it now" (`ls .git/objects/info`): verify what a fresh lab repository contains and make the answer definite.
- V120: hash cards show words, fingerprints cut to 8 characters; use the long-value form when available.
- V121: three dated paragraphs now start with words; check the section 16.16 table still highlights the right row.
- V126 (`M`), V132, V133 (`A-B`): placeholder commits; use real IDs if a sandbox replay prints them and the script's snippets contain them, else keep and say so.
- V128: three merge methods side by side now possible; replace the ASCII comparison if the new scene matches it.

## Batch 5 (V134 to V166)
- V135: stage direction says "the five question marks are yours" while the narration solves the first aloud and says four remain: make the two agree (the direction is on screen).
- V137: try-it answer "most often N" for `%G?`; fine, but say it is the result with no signing configured.
- V140: third graph state draws commits as ghosts after `git branch -D` though HEAD's reflog still names them: use the "reflog-only" style.
- V142: step name "Run the tests" versus the file's "Run the tests with the standard library": use the file's name if it fits.
- V158: the prediction says "two new lines above `run`" but the diff adds three (`env:` and two variables): correct the narration to match the diff.
- V160: the second `[DIAGRAM]` direction renders as a callout showing only the word "no" (already so in the original): fix the direction's rendering or the script.
- V156: hook uses trigger, cache, publishing identity before they are defined: define within the word limit or reorder.
- V164: the graph leaves out two side branches (`7fae871`, `54093fe`); V160 version labels are the editor's wording: check.
- V147: the `ci` scene card reads `on: push` although `workflows/01-tests.yml` has two events; the second scene draws a failing run that was never executed (narration says so): keep the "not executed" wording visible. The question "which ruff step fails on the unused import" is left open: answer it from the lab manual or the linter's documentation, or keep it as homework.
- V146: Step 2's prediction is partly given away by Step 1's transcript: move the prediction or reword it.
- V148 (tag-push prediction), V152 (billing quiz), V155 quiz: answers are derived, worded "derived from the documentation": re-check against the textbook.
- V149: graph link `e39e6de` ← `57c8425` comes from a sandbox replay, not from the transcript.
- Times of day and dates spelled in words (V162, V166): spot-check subtitles.

## All ranges
- DIAGRAM sections had no narration (the text of a `[DIAGRAM]` direction is not read); editors added a short paragraph or placed the try-it answer over the drawing. Check no diagram is held in silence.
- In V156 to V166 the interview question is on screen only; narration says "Read the question on screen" and pauses.
- Definitions written without a glossary entry (CI, API, YAML, shell, exit status, credential, token terms and others): keep one wording per term across videos; add the terms to `reference/glossary.md` in the final pass.

## Batch 6 (V167 to V201)
- V167: corrected on 2026-10-06 (textbook 21B.17 and narration): the three later commits changed because their trees lost `.env` too and because the parent changed. A scene must not draw "only the parent differs".
- V168: `merge` scene draws the merge base as the first commit although older history exists; same in V172 (which also leaves out side commit `5928b76` on `main`) and V174: use elision ("... older commits") when available.
- V169 quiz uses "13 of 20" (not in the script; chosen below the stated 14 of 20): check against the gate rules.
- V170: `a83a713` drawn as a ghost while the reflog still names it: use the "reflog-only" style.
- V171: terminal direction corrected to "two features before the release, a third after" (matches `labs/ch27/git-flow.sh`). "Branch by abstraction" (V171) and "MCP" (V178) are undefined: add a one-sentence definition only if the textbook supports one.
- V176: `trees` tag uses `commits=` with one ID (documented two-ID form): confirm it renders as intended.
- **V180, V186 to V190 (priority): the DIAGRAM section comes before the demo, and its drawing and narration show the cause before the terminal reveal.** The scene pass must make the pre-demo picture show only the symptom ("what we know so far"), and bring the cause picture after the reveal; narration in the DIAGRAM section may be reworded for this, without adding facts.
- V180: director notes are read aloud as narration ("Show the state diagram now", "Show the root-cause box"): turn them into directions or reword to address the viewer.
- V182: "Any file in capitals that is not in this listing is a sign of activity" is loose (`ORIG_HEAD` stays after an operation ends): make it precise from the textbook.
- V179, V186, V190: some section openers were dropped for the word cap; acceptable, note only.
- V188 (14 to 16 commits), V189, V190 (about 10): graph legibility unchecked; inspect frames.
- V184: catalog group names "submodules, LFS and scale" undefined.
- V191 hook: "a flaky failure does not repeat identically ... This one does both" reads ambiguously: reword from the textbook. Do not draw the runner's one-commit clone with ghosts; use the "absent from this clone" style.
- V193, V196: a quiz is held over a table that lets the viewer read or compute the answer: let the table leave first.
- V194 try-it uses `git ls-remote origin` (read-only, but contacts the viewer's remote): say so in the narration or replace with a local command.
- V196: the viewer is asked to predict "before you read the check" while the check output is in the same transcript: split the reveal if the storyboard allows.
- V199: "Predict two ways in which it will stop working" has no pause or answer (left to the lab): add a pause and point to the lab.
- V200: the `--ref-action=print` line shows `1653f1a` while the real advance lands on `863b8b5`: verify in the sandbox why (most likely the committer time differs between the two runs) and say it in one sentence, or leave unmentioned if not verified.
- V200 try-it `git history -h`: say it needs Git 2.54 or newer (the script's own statement), and that older versions report an unknown command.
- V201 farewell names course materials taken from other scripts: check each named file exists.

## Found in the scene pass (for build inspectors)
- V058, V060, V064: the DIAGRAM section shows an answer that a later prediction asks for (left in place by the scene pass): reorder or mask at inspection.
- V081: a transcript was shortened to a silent hold although its paragraph walks through the repair commands: restore the terminal there.
- V086, V087: "Unverified" / "volatile" / "Outdated advice" callouts are shown for 5 s and not read.
- V056 hook: `L2` → `L2'` is the editor's schematic choice.
- V039–V044 and V056–V066: not every tag had a second `--look` render (machine load); the build inspection must look at each scene's last frame.
