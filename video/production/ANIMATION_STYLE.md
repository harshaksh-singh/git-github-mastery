# Animation style of the course videos

What the animation layer borrows from the explanatory style of the YouTube channel 3Blue1Brown, what it deliberately does not copy, and the complete vocabulary a script uses to ask for an animated scene. Sections 0 and 7 to 11 are the reference for script editors; sections 1 to 6 describe the style.

To try a tag before you put it into a script:

```text
python3 tools/video_animtest.py --look 'bisect: commits=16 first_bad=11' --name try
```

It renders the whole scene, checks every state for text that is too small, cut short with "…", cut off at the edge or lying on other text, and writes a contact sheet of twelve frames to `video/production/.cache/look/try/sheet.jpg` (`--full last` also saves the last frame at full size, `--part 5` uses the palette of part 5).

## 0. Topic → scene

| You want to show | Scene | Section |
|---|---|---|
| a history that grows, labels that move, several states of one picture | `graph` | 9, 10.1 |
| marks on commits (good, bad, pass, fail, `<`, `>`, `=`), a shaded range `A..B`, roles (base, ours, theirs), notes | `graph` (keyword parts) | 9 |
| two or three repositories side by side: fetch, push, a rejected push, a forced update, `pull --rebase`, a fork, a CI clone, a moved tag, a stale clone | `remotes` in the graph notation (`[name] ... \|\| [name] ...`), also under the names `fetch`, `prune`, `forks`, `stale`, `repos` | 9, 10.6 |
| the six-step story "a teammate pushes, you fetch, pull, commit, push" | `remotes` | 10.6 |
| fast-forward, three-way merge, both side by side; a cherry-pick or a revert as a three-way merge | `merge` | 10.2 |
| a rebase: lift, copy, new IDs, a stop at a conflict, `--onto` | `rebase` | 10.3 |
| the todo list of an interactive rebase | `todo` | 10.19 |
| a label yanked back and found again in the reflog | `reflog` | 10.4 |
| the recovery ladder: reachable, only in the reflog, unreachable, pruned | `ladder` | 10.21 |
| working tree, index, HEAD: add, commit, restore, the three resets, a new file, a sparse checkout, line endings and filters | `trees` | 10.5 |
| commit → tree → blobs; any objects: a tag object, nested trees, a gitlink entry, a missing blob | `objects` | 10.7 |
| content addressing: same content, same ID; two hash functions; a fingerprint | `hash` | 10.8 |
| the lab sandbox and your real setup | `sandbox` | 10.9 |
| bisect | `bisect` | 10.12 |
| blame, and what `-w`, `-M` or an ignored revision change | `blame` | 10.18 |
| stash | `stash` | 10.13 |
| lightweight and annotated tags | `tags` | 10.14 |
| a push in parts: refspec, the two gatekeepers, the lease | `push` | 10.20 |
| a shallow or partial clone | `shallow` (graph notation with `absent:`), `objects` with `missing=` | 9, 10.7 |
| a submodule (a pointer into a second repository), a subtree | `submodule`, `subtree` (graph notation, `link:`) | 9 |
| worktrees, Git LFS, loose objects and packs, a bundle, two `.git` layouts, a fork network's object store | `stores` | 10.16 |
| hooks, rules a push meets one after the other, a response sequence | `gates` (also `hooks`, `response`) | 10.11 |
| rulesets that add up, permission levels, precedence | `layers` (also `ruleset`, `permissions`, `precedence`) | 10.15 |
| CODEOWNERS, `.gitattributes`, `includeIf`, `~/.ssh/config`: which line wins | `match` (also `codeowners`, `attributes`, `includeif`) | 10.17 |
| a sequence between parties: a credential helper, HTTPS or SSH authentication with the place where it fails, an OIDC token exchange, a trust boundary | `flow` (also `auth`, `oidc`, `sequence`, `relay`) | 10.10 |
| a table read row by row: base / ours / theirs / result, a lease check, a listing | `walk` (also `table`) | 10.22 |
| a decision tree; a state diagram (the life of a pull request) | `decide`; `lifecycle` or `states` | 10.23 |
| a few numbers (pack sizes over maintenance runs) | `bars` | 10.24 |
| a few statements that arrive one by one and are then ticked, crossed or locked (answers, conditions, options) | `cards` | 10.28 |
| what a signature covers, line by line of a commit or tag object | `objects` with `cards=` and `signed=` | 10.7 |
| "Git says / GitHub says" in two lanes | `walk` with two columns, or `layers` with two layers | 10.22, 10.15 |
| the pull request flow, a blocked merge, a dismissed approval, squash and rebase results | `pr` | 10.25 |
| three merge methods side by side | `methods` (graph notation, panels in rows) | 9 |
| a CI run end to end, a failed run, a run skipped by a path filter | `ci` | 10.26 |
| one workflow run in detail: jobs with needs, a matrix, the token, cache and artifact, an environment gate, concurrency | `run` | 10.27 |
| a mutable tag that is moved, against a pinned commit | `pin` (graph notation) | 9 |

Scenes of the platform (`pr`, `ci`, `run`, `layers`, `gates`, `match`, `flow`, `decide`, `stores`, `cards`) are schematic diagrams. They do not imitate GitHub's interface, and they show no fact of their own: every name, number and sentence on them is a parameter the script supplies.

## 1. What was studied

- The channel (`youtube.com/@3blue1brown`), its lesson pages (for example "But what is a neural network?" and "But what is the Fourier transform?" on `3blue1brown.com/lessons`), and its FAQ. Video cannot be watched from a text tool, so the notes below rest on those pages and on what is documented about the style.
- Manim, the engine behind those videos: the Community Edition documentation (`docs.manim.community`, the building-blocks tutorial and the example gallery) and the original repository (`github.com/3b1b/manim`, MIT licence).

Manim's model is three things: **mobjects** (objects on screen), **animations** (an interpolation of an object between two states, with a run time and a rate function) and **scenes** (`play` an animation, `wait`). The gallery is a catalogue of the same few moves: `Create` and `FadeIn`, `Transform` and `ReplacementTransform`, `MoveAlongPath`, `GrowFromCenter`, value trackers and updaters that keep dependent objects in step, and camera scenes that follow or zoom.

## 2. What this course takes from it

| Technique | How it is done here |
|---|---|
| Nothing is cut in: objects are created, moved, transformed | Commits pop in with their edge drawing first; labels slide along an arc when a ref moves; terminals type; rows and bullets arrive one at a time. Between unrelated slides there is an 8-frame crossfade, never a hard cut. |
| One new idea on screen at a time | A scene is a list of named **steps**; a beat of narration plays one step. Table rows that have not been discussed wait as faint ghosts. |
| Motion in step with the voice | A cue fires at the place in the paragraph where its subject is named (a commit ID, a branch, a command), not only at the start of the paragraph. |
| Consistent colour meaning | See section 4. The same colour always means the same thing, in every part of the course. |
| Highlighted focus | A ring swells around the commit or label being talked about; everything else stays put. The current table row or bullet is bright, the others dim. `point_<step>=name` lands a short arrow on a named spot. |
| Camera | Holds drift in by at most 1.4 % and back out on a 20-second cosine (anchored at the bottom-left corner, so the progress bar and the accent bar stay put), and the mascot never stops breathing: no frame is frozen. The drift restarts with each new picture. There are no cuts to close-ups and no pans across a scene. **A picture that grows is centred on what is on screen so far.** A commit graph re-fits in 0.8 seconds with an ease when a later step needs more room, never more than 25 % closer than the final framing; with several panels every panel does so by itself. The schematic scenes of sections 10.10 to 10.28 and `objects` with `cards=` do the same with a camera of their own: it stands up to 25 % closer while the picture is small and moves out as boxes arrive. The camera starts 0.35 seconds before what the step adds, and a step is not over before the camera has settled, so a new commit or label always arrives inside the frame. `camera=off` keeps the final framing from the first frame; `camera=follow` switches this camera on in `objects` and `hash`, which batch one shows framed for their last step from the first frame (the other scenes of batch one fill their frame from the start). |
| Minimal text | Scenes carry a short title, one caption line and one command line. The narration carries the rest. |
| Questions to the viewer | `[PAUSE]` beats and beats that end in a question put the mascot in its "thinking" pose with a question mark. |
| A character that reacts | Twig, section 5. |
| One picture built up over time | A scene can leave and come back in the state it had (`step:`), get a new caption while it is held (`say:`), or start again (`replay:`), so the same diagram serves the concept, the mental model, the diagram section and the recap. |
| Rate functions | Every tween has an ease: `out` for arrivals, `inOut` for moves, `back` (a small overshoot) for pops. Linear only for typing. |
| Deterministic rendering | Like Manim, a scene is a pure function of time. `window.__anim.seek(t)` draws the frame for time `t`; nothing uses the real clock. |

## 3. What is NOT imitated

- **Their mascot.** The pi creatures are 3Blue1Brown's. This course has its own character with a different body, face and palette (section 5).
- **Their palette and look.** No blue-and-brown scheme, no dark-grey Manim background, no LaTeX typography. Colours come from the course's own part palettes (`PARTS` in `tools/build_thumbnails.py`), on the course's own slide frame.
- **Their music.** Vincent Rubinetti's scores are theirs. These videos have no music at all: only the voice and three quiet, synthesised interface sounds (a pop, a key tick, a soft whoosh), generated with ffmpeg.
- **Manim itself.** Nothing is installed. The motion is HTML, SVG and JavaScript in `tools/anim/`, captured frame by frame through Chrome's DevTools protocol, and assembled by ffmpeg.
- **Real 3D.** Out of scope. "3D" here means pseudo-3D drawn in SVG: isometric slabs (a front face with two shaded sides), stacked sheets, soft drop shadows. There is no 3D camera, no perspective, no lighting, no rotation in depth.
- **Their voice and wording.** Scripts are the course's own.
- **GitHub's interface.** Platform scenes are diagrams of boxes, rows and arrows. No screen of the product is redrawn.

## 4. Colour meaning

| Thing | Colour and shape |
|---|---|
| A commit | neutral grey outline on the dark background; its ID in Menlo |
| The current branch, HEAD's branch | the part's accent colour, filled; `HEAD` is a small white chip beside it |
| Any other branch | light outline, not filled |
| A remote-tracking label (`origin/main`) | dashed grey outline |
| A tag (`v0.1.0`) | its own shape: a luggage tag, pointed at the left, with a hole; white outline. Never drawn as a branch chip |
| An annotated tag | the same tag shape, an arrow, and a small square box "tag" with the ID of the tag object, which stands between the tag and the commit |
| A special ref (`ORIG_HEAD`, `MERGE_HEAD`, `FETCH_HEAD`, `CHERRY_PICK_HEAD`, `REVERT_HEAD`, `REBASE_HEAD`, `BISECT_HEAD`, any `..._HEAD`, `HEAD@{1}`, `main~2`, `refs/bisect/bad`, or a name written `special:name`) | a small hollow chip with square corners, the size of the `HEAD` chip: a name Git writes or resolves for itself, not a branch |
| New, or in focus | the part's second colour (accent2), with a glow |
| A role on a commit (base, ours, theirs, P, C) | a small pill outlined in accent2 |
| A set of commits (a range such as `A..B`) | a translucent band in accent2 behind them; a second set (`A...B`) in the accent colour |
| A mark on a commit | a pill above it: green for good and pass, red for bad, FAIL, conflict, rejected, damaged, missing and "first bad", amber for skip and dangling, accent2 for `<`, `>`, `=` and "test this" |
| Unreachable ("ghost") | dashed outline, faded to 38 % |
| Reachable only from a reflog | dashed outline, **not** faded: something still names it |
| Not visited (`--first-parent`, ruled out by bisect) | solid but dark |
| Not in this clone (behind a shallow boundary, left out by a partial clone) | hatched, dotted outline |
| A commit nobody names in the picture | a smaller plain dot; a commit whose ID is never printed: a circle with a thin solid outline and a word in italics under it (never dashed: dashes mean "only a reflog names it" or "unreachable"); commits that are not drawn: three dots with "14 more" |
| A destructive action | red `#ff5c5c`, **always with a warning triangle** (Part 7's accent is also red, so colour alone is never the signal). A command line is marked destructive by a `!` in front of it (`cmd:!git_reset_--hard`, `cmd_<step>=!git_clean_-fd`): the `!` asks for the triangle and is not shown |
| Success (a passed check) | green `#3fb950`, with a tick |
| A failed check, a blocked merge, a gate that stops | red `#ff5c5c` with a cross (a cross, not a triangle: nothing is destroyed) |
| A pending check, a review not given yet, a gate that waits | amber `#e3b341`: a dashed ring, or a question mark when the state is unknown |
| Code, commands, IDs, file names | Menlo |

## 5. Twig, the mascot

Twig is a commit dot with two eyes, two small feet and a forked twig growing from its head: a branch with two tiny commits on it. The body is cream; the twig takes the accent colours of the part. It stands in the bottom-right margin (a 170 x 200 px sprite; in animated videos the slide content is drawn at 95.5 % so that this margin is always free), breathes, and blinks every few seconds.

| Pose | When |
|---|---|
| curious | default: looking toward the content |
| thinking (question mark) | `[PAUSE]`, a beat that ends in a question, the interview question |
| surprised (exclamation mark) | the hook |
| worried (raised brows, a sweat drop) | any beat with a red risk label; at a destructive scene step (`restore`, `reset`) only while that step plays and for 2.5 seconds after it, not for the whole paragraph |
| celebrate (jumping, sparkles) | the recap |
| pointing (leaning toward the scene, a small arrow) | only when a script asks: `point_<step>=name` on a scene (the scene draws an arrow on that spot at the same time), or `twig_<step>=pointing` |
| nod (two small nods) | only when a script asks: `**[ANIMATION]** twig: nod` before a paragraph, typically the answer after a prediction |
| careful (leaning back, level brows, a small caution sign) | only when a script asks: `twig: careful` or `twig_<step>=careful`, for a 🟡 caution that is not a red risk |

Twig hops once whenever its pose changes, and is hidden while the thumbnail is on screen. It never speaks and never moves out of its corner. Use the three asked-for poses sparingly: at most two or three times in a video.

## 6. How a beat gets its animation

1. **Automatically, by slide kind.** Terminal: the window arrives, each command types itself, its output scrolls in; when the paragraph names several commands, each waits for its mention. Bullets: one at a time. Table: rows cascade in, or arrive row by row when the narration walks the rows in order. Callouts, title and section cards: their parts rise in turn. Any other drawing in a `text` fence: drawn in line by line.
2. **Key points** (one sentence on screen) are laid out in one of four ways, chosen from the sentence itself:
   - a **question** (the sentence ends in a question mark): centred, very large, with a faint question mark behind it;
   - a **contrast** ("A, not B", "A instead of B", "A rather than B"): two cards side by side, the true one in the accent colour, the other dashed and grey;
   - a **count** ("Four verbs: ...", "Two things today"): the number very large on the left, counting up, with its noun under it;
   - a **statement**: left-aligned large type, with a small animated drawing beside it when the sentence names something that has one (commit, branch, merge, folder, file, lock, warning, clock, hash, snapshot, terminal, server, cloud, book, target, ladder). The drawing alternates sides, and the same drawing is never used on two key points in a row.

   In every layout one or two key terms take the accent colour and underline themselves after the sentence has arrived, and code spans are drawn as chips.
3. **By recognising a commit graph.** A `text` fence that is an ASCII commit graph (IDs or letters joined by `---`, `/`, `\`, with branch labels, `(HEAD -> main)`, `^` pointers, and optional side-by-side or stacked "Before / After" panels) is parsed and replayed by the commit-graph scene: commits grow in order, labels slide between the panels, the commit or label being named pulses. If anything in the drawing is not understood, the still drawing is used and drawn in line by line. Check a drawing with `python3 tools/video_animplan.py --graph FILE`.
4. **By an explicit tag in the script** (sections 7 to 10).

## 7. Stage directions

A stage direction stands on a line of its own:

```text
**[ANIMATION]** scene: words and key=value parameters
```

| Direction | Effect |
|---|---|
| `scene: ...` | the scene of that name arrives (the names are in section 0; the old synonyms `commit-graph`, `three-trees`, `object-model`, `content-addressing`, `lab`, `pull-request`, `pipeline`, `rescue` still work) |
| `step: copy` | the scene on screen advances to that step; a scene that has left returns in the state it had and goes on from there |
| `step: rebase.copy`, `step: power.state-2` | the same, naming the scene: by its scene name, or by the `id=` it was given. Use it when two scenes of a video have a step of the same name |
| `say: A new caption` | the scene on screen (or the most recent one, which returns) gets this caption instead of the one it shows; `say: off` removes the caption. The picture does not move: a scene that `say:` brings back plays no step, also when it has steps left (only a `step:` tag advances it then). The next step brings its own caption again. The text may be written with spaces, or like a parameter value (`say: The_tip_is_ORIG__HEAD`: no space, `_` is a space, `__` one underscore) |
| `replay:` or `replay: hash` | the most recent scene (or the most recent one of that name or id) starts again from its first step, without repeating its tag |
| `twig: nod` | the mascot's pose for the next paragraph: `nod`, `careful`, `pointing` (or any pose of section 5) |
| `end` | the scene leaves; what follows is read over key points again. `end` replaces nothing: a `**[DIAGRAM]**` direction or a `text` fence directly after it is shown as usual |

Rules:

- The paragraphs that follow a scene tag are read over it, until a bold lead-in (`**Topic.** ...`) after the first paragraph, another stage direction, a list, a table or a fence replaces it.
- **A scene tag with no `step:` tag plays all its steps over the paragraphs that follow it.** Each step goes to the first paragraph that names it (each scene has a short list of cue words per step, `CUE_WORDS` in `tools/video_animplan.py`); steps nobody names are spread evenly. A step called `1`, `2` ... (the schematic scenes) has no cue word: a digit in the narration says nothing about it, so these steps are always spread evenly, or placed with `step:` tags or `at_<step>=`. If a picture must wait for its paragraph, put a `step:` tag before that paragraph. **With `step:` tags**, each tag advances the scene to the step it names, and the paragraphs after it are read over that state.
- **"With `step:` tags" is decided per run**, a run being the paragraphs between the scene's arrival (its tag, a `step:` or `say:` that brings it back) and the next thing that takes the screen. A `step: id.x` further down, after another scene or after `end`, does not hold the steps back: if the paragraphs right after the scene tag have no `step:` tag among them, every step is played over them, and the later `step: id.x` finds nothing left to play. To show only the first step now and the rest later, put `step: <first step>` directly after the scene tag, or stop the scene with `steps=`.
- Inside a paragraph, a step starts where its cue word is spoken, not at the first word. For most scenes that is the first word of the step's list that occurs in the paragraph. For a commit graph it is whichever of the step's cue words is spoken first: `state-1` (the labels) listens for "names", "label", "branch", "point"; `state-2` for "after the commit", "first,", "moves", "moved", "follows", "slides", "now"; `state-3` for "then", "second,", "finally", "moves", "moved". A step whose words do not occur is placed evenly between its neighbours, and no step starts later than 86 % into the paragraph. So when one paragraph plays several states, write it in the order of the picture ("First, ... Then ..."). `at_<step>=40` and `pace=quick` (section 8) set the timing by hand.
- **A `step:` tag keeps the scene on screen.** The paragraph after it is read over the scene even when it starts with a bold lead-in, so one scene can be held across several topics by putting a `step:` tag before each of them. (The older form, `end` followed by `step:`, still works: the scene returns in the state it had.) `say:` keeps the scene in the same way.
- A paragraph read over a scene is not drawn: the scene has the screen. A risk label that must be seen belongs on a key point, before the scene or after `end`.
- A scene tag (or a `step:` tag) placed directly before a `text` fence, or before a `**[DIAGRAM]**` direction with its fence, **replaces that drawing** in the video. The fence stays in the script for the book and the teleprompter. `end`, `say:`, `twig:` and `replay:` do not replace a drawing. A `replay:` directly before a drawing would play the scene with nothing read over it while the paragraphs go to the drawing: the storyboard reports that as a warning. Put the `replay:` after the drawing, or put a `step:` tag before the drawing to replace it.
- A scene tag directly after a quoted `**[ON SCREEN]**` direction or an on-screen table, with no paragraph between them, holds that text or table in silence for a few seconds and then shows the scene. The storyboard reports it (as a warning in its output; the plan is not changed, and batch one has three such places). Put the scene tag after the first paragraph, or remove the direction.
- Naming steps in the tag chooses them: `trees: add, commit` plays up to the last one named (`setup`, `edit`, `add`, `commit`); a list that starts with the scene's first step is taken literally (`trees: setup, edit, add, commit, reset` skips `restore`). `steps=a,b,c` plays exactly these steps in this order; it is the only way to play the steps listed as "only with `steps=`" in section 10. To stop a scene early by design, list the steps you want: `merge: three-way ... steps=setup,merge-base`.
- A scene with nothing read over it plays all its steps and holds about three seconds per step.
- A tag that is not understood is reported as a warning by `make.sh storyboard VNNN` and ignored (a `say_` or `cmd_` for a step the scene does not have counts as not understood). Scripts with no tags build exactly as before.
- A `**[PAUSE]**` after a paragraph that asks the viewer to predict ("Predict ...", "Say it out loud", "I'll wait", "Fast-forward, true merge, or nothing?") is held for 4.5 seconds instead of 2, and the mascot thinks.

## 8. Parameters every scene understands

`key=value`, separated by spaces. In a value that is text, `_` is a space and `__` is one real underscore. Lists are separated by commas; **when an item itself contains a comma, separate the items with `|`** (`lines=first,_with_a_comma|second`, `subs=files,_as_you_see_them|the_staging_area|the_last_commit`: with one `|` in the value, commas no longer separate anything). Records (a row of a table, a rule, a message) are separated by `|` and their fields by `:`; the last field keeps any further colons. A value cannot contain a space. A semicolon inside a value belongs to it (`rows=1:A:git_add;_git_commit`), except in the graph notation of section 9, where `;` separates the parts of a state and therefore ends every value; a semicolon at the very end of a value is never part of it.

| Parameter | Default | Effect |
|---|---|---|
| `title=The_Monday_copy` | the scene's own title; `graph`, `pr` and the schematic scenes have none | the title in the top-left corner. `title=off` removes a default title |
| `title_<step>=New_title` | | the title changes when that step plays (`title_<step>=off` removes it). Use it when a scene returns under another topic |
| `steps=outside,shield,room` | all steps of the scene, except those marked "only with `steps=`" | plays exactly these steps, in this order |
| `captions=off` | on | no caption line (in `merge` also no command line: for analogies) |
| `say_<step>=text` | the scene's caption for that step | replaces the caption of one step, for example `say_commit=The_branch_file_changes,_HEAD_does_not`. `say_<step>=off` removes it. A step with a hyphen is written with an underscore: `say_merge_base=...`. In a `graph` it works for every step (`say_state_2=...`). The schematic scenes (`flow`, `gates`, `layers`, `walk`, `match`, `decide`, `stores`, `bars`, `blame`, `todo`, `push`, `ladder`, `cards`, `run`) have no captions of their own: there `say_<step>=` puts a caption on the line under the title, which stays until another step brings one or `say_<step>=off` removes it |
| `cmd=off` | on | no command line in the whole scene |
| `cmd_<step>=text` | the scene's command for that step | sets the command line of one step (`cmd_add=git_add_-p`), `cmd_<step>=off` hides it. `cmd_<step>=!git_clean_-fd` draws it as destructive: red, with the warning triangle; the `!` is not shown |
| `camera=off` / `camera=follow` | section 2, Camera | no re-fit; or a following camera in `objects` and `hash` |
| `id=name` | | a name for this scene, for `step: name.step` and `replay: name` |
| `at_<step>=40` | by cue word, else spread evenly | that step starts 40 % into its paragraph (in every scene, also in a `graph`, a preset such as `bisect`, and `objects` with `cards=`) |
| `pace=quick` | | steps without a cue word follow each other closely from the start of the paragraph instead of spreading over it (a one-paragraph `sandbox`) |
| `point_<step>=name` | | after that step a short arrow lands on the named spot and the mascot points. Spots: a commit ID or a label of a graph, the title of a box (`origin`, `your clone`, a `stores` box, a `flow` actor, a `gates` gate, a `layers` layer, a `run` job, a `decide` node id, an `objects` card ID, `card` in `pr`) |
| `twig_<step>=careful` | | the mascot's pose while that step plays and for 2.5 seconds after it |

A caption that is too long for the frame shrinks to fit; keep one under about 80 characters.

**Text that does not fit.** In the schematic scenes a text first shrinks to the smallest size (28 units), then wraps where the scene has room for another line (a `stores` row, title or arrow label, a `walk` cell, a `gates` name, owner or note, a `flow` actor, a `decide` edge label), and only then is cut with "…". Every cut is a finding of the layout check: `--look` and the self-test print `text cut short: "…" (in full: "...")`. Shorten the text when you see it.

## 9. The graph notation

The `graph` scene, the panel form of `remotes`, and the topic names `fetch`, `prune`, `forks`, `stale`, `repos`, `shallow`, `partial`, `methods`, `submodule`, `subtree`, `queue`, `pin` are all written in one notation. Steps: `grow` (the commits), `state-1` (the labels), then `state-2`, `state-3` ... for each `=>`; `name:` gives a state another step name.

```text
**[ANIMATION]** graph: A-B-C main; B-D-E feature; HEAD=main
```

**Chains.** A state is a list of parts separated by `;`. A part is a chain of commits joined by `-`, followed by the names that point at its last commit. A commit is drawn to the right of all its parents, and appears only after them, so a real merge is written with real IDs: `d4c9fab-bb904cd-191bbd1-ae6795c main; bb904cd-79ff6d7-59c914e feature/f1; 59c914e-ae6795c`. The first chain is the top row; a later chain that brings new commits opens a new row (a merge commit named alone at the end of a chain stays on its first parent's row). A chain written with `^` in front (`^d1e8f22-6a04691 fix/typo`) puts its new commits on a row above the first one: use it when a side branch drawn below would send its edge through the ID of the commit it leaves. One commit is enough (`C main`), and a graph may have up to 48 commits; with many, letters stay readable longer than IDs.

| Commit written as | Drawn as |
|---|---|
| `A`, `6eab4a9`, `C′` | a commit with that letter or ID (up to 8 characters) |
| `*`, `*1`, `*2` | a plain dot: a commit nobody names (number them to tell them apart) |
| `?yours`, `?new_commit` | a circle with a thin solid outline and the word in italics under it: a commit whose ID is never printed (up to 40 characters; it is never dashed, so it cannot be mistaken for `reflog:` or `ghost:`) |
| `...`, `...14`, `...older` | three dots: commits that are not drawn. A bare `...` has no words (`A-...-B` is A, an elision, B); `...14` says "14 more", `...older` says "older". A graph can have one bare `...`; a second elision needs a name or a number |

**Labels.** After a chain: branch names; `v1.2.3` is drawn as a tag by itself. A prefix says the kind: `tag:name`, `atag:name` or `atag:name#131e7a7` (annotated: the tag object and its ID stand between the tag and the commit), `remote:name` (remote-tracking style for a name that does not start with `origin/` or `upstream/`), `branch:name` (a branch even if it looks like something else), `special:name` (the small hollow chip; `refs/stash`, `refs/pull/1/head` and `AUTO_MERGE` need it). Two labels with the same text: add `#something` to one of them, which is not drawn (`remote:origin/main branch:origin/main#local`; `MERGE_HEAD` on two commits: `MERGE_HEAD` and `special:MERGE_HEAD#2`). `tags=a,b` as a parameter is the same as `tag:a tag:b`.

**HEAD.** `HEAD=main` (attached), `HEAD=8c6d240` (detached: the chip sits on the commit), `HEAD=none` (no HEAD in this picture: a bare repository, a picture about objects). Without any `HEAD=` part HEAD attaches to `main`, or to the first label: write `HEAD=none` when that is wrong.

**States.** `state => state` continues the same picture: new commits grow, labels slide to where the new state puts them. A state lists everything that should be on screen in it. **A state that starts with `+` keeps the whole state before it** and changes only what it names: `+ C main` moves `main`, `drop:name,id` removes a label, a note, a role or a mark. `drop:` takes the name as it is drawn (`drop:v1.0` removes the tag written `atag:v1.0#131e7a7`), a commit ID (its mark and its notes go), or the word of a mark (`drop:same`, `drop:approved_here`: every mark with that word).

**Where a commit stands is decided once**, in the first state in which it appears, from the chains of that state: its row, and its column to the right of its parents. Later states, with or without `+`, never move it. So write the first state of a commit with the chain that gives it the place you want (the first chain is the top row, `^` puts a chain above), and do not expect a later state to re-draw a history that was, say, rebased: the copies are new commits with places of their own.

**What `+` keeps, and what ends by itself.** The lists `ghost:`, `reflog:`, `dim:` and `absent:`, the marks, notes, roles and ranges stay until a state changes them. A list is replaced by writing it again (`ghost:` alone empties it). Two things need no word: a **branch or tag** that a `+` state puts on a commit makes that commit and its ancestors solid again (they leave the inherited `ghost:` and `reflog:` lists; a name Git resolves for itself, such as `ORIG_HEAD` or `HEAD@{1}`, does not), and a commit removed with `gone:` **comes back** when a later state names it in a chain again (`+ B-C main`).

| Keyword part (inside a state) | Meaning |
|---|---|
| `ghost:id,id` | unreachable in this state: dashed and faded (`ghost=id,id` as a parameter is the same for the last state) |
| `reflog:id,id` | only a reflog names them: dashed, not faded |
| `dim:id,id` | not visited: solid but dark |
| `absent:id,id` | not in this clone: hatched (use it with `...` for a shallow boundary) |
| `gone:id,id` | deleted: the commit and its edges leave the picture, until a later state names the commit in a chain again |
| `good:id` `bad:id` `skip:id` `pass:id` `fail:id` `test:id` `first_bad:id` `dangling:id` `damaged:id` `missing:id` `pruned:id` `conflict:id` `rejected:id` | a mark above the commit |
| `left:id` `right:id` `same:id` | the marks `<`, `>`, `=` of `git log --left-right` and `--cherry-mark` |
| `mark:word:id,id` | any short word as a mark (`mark:approved_here:C`) |
| `note:id:free_text` | words under the commit (a note stays while the following states list it or start with `+`) |
| `role:id:base` | a role pill: `base`, `ours`, `theirs`, `P`, `C`, `HEAD^2` |
| `range:id,id,id:A..B` | a shaded set with its name (the name is optional); `range2:` is a second set in the other colour; `range:` alone removes it |
| `tree:id:4b825dc`, `sub:id:gen_3` | a second line under the commit: its tree ID, or any short text (a generation number, a date) |
| `say:text`, `cmd:text`, `title:text` | the caption, the command line and the title of this state. `cmd:!git_push_--force` is drawn as destructive: red, with the warning triangle, and without the `!`. The caption and the command line stay through the following states until one replaces them; `say:off` and `cmd:off` remove them |
| `name:word` | this state's step is called `word` instead of `state-N` |
| `view:id,id` | the camera looks only at these commits (a long history that scrolls); `view:` alone looks at everything again |
| `link:id>id:label` | an arrow from a commit of this panel to a commit of another panel (a superproject's commit that records a commit of a submodule) |

**Panels.** `[name] state || [name] state` draws several repositories or views side by side, each with its own commits, labels and HEAD. A panel left empty in a later state stays as it was. When a state adds to one panel a commit that another panel already shows, the commit flies across (a fetch, a push, a clone); `fly=off` stops that. `layout=rows` stacks the panels (the default for `methods` and `queue`, and for any picture of three or more panels in which one has eight or more commits in a row: side by side each panel is about 500 units wide and the IDs would fall below a legible size; `layout=columns` keeps them side by side all the same); the panel whose name starts with `*` or is `origin`, `upstream` or "the server" is drawn in the accent colour. Under the names `remotes`, `repos`, `fetch`, `prune`, `forks`, `stale`, `submodule` and `shallow` the panels are drawn as repository boxes (`boxes=repos`), under `graph` and `methods` as plain frames.

| Parameter | Default | Effect |
|---|---|---|
| `dx=260`, `dy=170` | 190 and 150 (170 and 140 with panels) | the distance between columns and rows: raise `dx` when long labels on neighbouring commits collide |
| `layout=rows`, `layout=columns` | side by side; rows for three or more panels with a row of eight or more commits | panels one above the other, or side by side |
| `boxes=repos` | by scene name | repository boxes instead of plain frames |
| `fly=off` | on | no flight of a commit between panels |
| `captions=room` | room is kept when a state has `say:` or the tag has `say_<step>=` | keeps the caption line free for a later `say:` tag |
| `settle=on` | on for every graph that uses `+`, a keyword part other than `ghost:`, panels or one of the new commit forms; off for a graph written in the notation of batch one | a state ends when its fades and focus rings are over. Without it a state ends with its last label, and the held picture can show a ring or a fade half-way (the graphs of batch one are kept that way; add `settle=on` to an old tag to end it cleanly) |

Examples:

```text
**[ANIMATION]** graph: A-B-...14-C-D main; B-E-F feature; HEAD=none; note:B:merge_base; role:D:ours; role:F:theirs; range:E,F:main..feature => + range:E,F:main...feature; range2:...14,C,D; left:D; right:F

**[ANIMATION]** remotes: [your clone] A-B-C main; B origin/main || [origin] A-B-D main; HEAD=none; cmd:git_push => + rejected:C; say:The_push_is_rejected:_not_a_fast-forward || => [your clone] A-B-D-C′ main; D origin/main; ghost:C; cmd:git_pull_--rebase || => + C′ origin/main; cmd:git_push || [origin] A-B-D-C′ main

**[ANIMATION]** prune: [your clone] A-B main origin/main; A origin/old-feature || [origin] A-B main; HEAD=none => + drop:origin/old-feature; cmd:git_fetch_--prune ||

**[ANIMATION]** shallow: ...older-C-D-E main; HEAD=main; absent:...older; say:A_clone_of_depth_3:_older_history_is_not_here

**[ANIMATION]** submodule: [superproject] A-B-C main; HEAD=main || [vendor/lib] P-Q-R main; HEAD=none => + link:C>Q:records_Q_(mode_160000) || + Q HEAD

**[ANIMATION]** methods: [Create a merge commit] A-B-M main; A-C-D; D-M; HEAD=none || [Squash and merge] A-B-S main; HEAD=none || [Rebase and merge] A-B-C′-D′ main; HEAD=none

**[ANIMATION]** pin: A-B-C main; B tag:v4; HEAD=none; note:B:pinned_by_SHA_stays_here => + C tag:v4; say:The_tag_is_moved
```

## 10. Scene reference

For each scene: what it shows, its parameters with their defaults, its steps, one example to copy, and when to use it. The parameters of section 8 work everywhere and are not repeated.

### 10.1 graph

A commit graph: first the commits, then the labels, then one step per further state. Notation and parameters: section 9. Steps: `grow`, `state-1`, `state-2` ... (or the names given with `name:`).

```text
**[ANIMATION]** graph: 6eab4a9-23b0907 main feature/x; HEAD=feature/x => 6eab4a9-23b0907-f5192c8 feature/x; 23b0907 main; HEAD=feature/x
```

Use it when the picture is a history: commits, names, and what a command does to them. Do not use it when a dedicated scene tells the story with the right motion (a rebase lifts and copies: `rebase`; a merge walks to the base: `merge`), or for more than about 20 commits with real IDs.

### 10.2 merge

Fast-forward, three-way merge, or both side by side. `merge: fast-forward feature into main`, `merge: three-way feature into main`, `merge: fast-forward versus three-way`.

| Parameter | Default | Effect |
|---|---|---|
| `X into Y` (words), or `main=`, `feature=` | `feature` into `main` | the two labels (`main=editor_one feature=editor_two` for an analogy) |
| `common=` | 2 | the history both sides share; its last commit is the merge base. A number (letters are used) or a list of labels or real short IDs |
| `main_only=`, `feature_only=` | 1 and 2 | the commits of each side (in a fast-forward `main_only` is ignored) |
| `merge_id=` | `M` | the merge commit's label; `merge_id=none`: no label (an ID the transcript never prints) |
| `base=the_Monday_copy` | "merge base" | the words under the merge base; `base=off`: none |
| `head=off` | on | no HEAD chip |
| `after=1` or `after=id,id` | none | commits made after the merge (three-way only); adds the step `after` |
| `as=cherry-pick`, `as=revert` | | the scene shows that a cherry-pick or a revert is a three-way merge whose result has **one** parent. `cherry-pick`: base = the parent of the last `feature_only` commit, ours = the tip of `main`, theirs = the picked commit. `revert`: a straight history (`common=`, default 4 commits), `target=id` is the commit undone (default: the one before the tip); base = the target, ours = the tip, theirs = the target's parent |
| `roles=base,ours,theirs` | these three words | the words on the three role pills (with `as=`) |

Steps: fast-forward `setup`, `check`, `fast-forward`; three-way `setup`, `merge-base`, `merge` (and `after`); versus `setup`, `check`, `fast-forward`, `merge-base`, `merge`.

```text
**[ANIMATION]** merge: three-way feature/rouge into main common=6eab4a9,03f74b9 main_only=9500b9e,e12f113 feature_only=22c856c,5351fa7,eaab34d title=Three_inputs,_one_new_commit
```

Use it when the point is how two histories are combined. Do not use it when the merge is only one event in a longer history (`graph`), or for a file-level view of base, ours and theirs (`walk`).

### 10.3 rebase

Commits are lifted, copied onto the new base as new commits, and the originals become ghosts.

| Parameter | Default | Effect |
|---|---|---|
| `X onto Y` (words) | `feature` onto `main` | the branch that is rebased and the new base |
| `common=`, `main_only=`, `feature_only=` (or `commits=`) | 2, 1, 2 | shared history, the commits only on the new base, the commits that are replayed: a number or a list of letters or real IDs (up to 8 each) |
| `new_ids=id,id` | the letter with a prime (`D′`); for a real ID no text | the IDs of the copies |
| `upstream=server`, `upstream_only=` | none; 2 | the three-point form `git rebase --onto <onto> <upstream> <branch>`: the commits of `upstream` that are not on the new base, from whose tip the branch leaves |
| `stop=1` | none | the rebase stops after that many copies with a conflict; adds the steps `conflict` and `continue` (`stop=0`: the first commit conflicts) |
| `rebase_head=on` | off | at the stop, `REBASE_HEAD` on the commit that does not apply |
| `orig_head=on` | off | at the end, `ORIG_HEAD` on the old tip |

Steps: `setup`, `lift`, `copy`, (`conflict`, `continue`,) `ghost`, `move`.

```text
**[ANIMATION]** rebase: feat/rerank onto main common=8afc6bd main_only=589d18b feature_only=5ee19f0,af65a92,bd62876 stop=1 rebase_head=on orig_head=on
```

Use it when the lesson is "a rebase makes new commits". Do not use it when the rebase is one event among others (`graph` with `ghost:`), and feed it from `todo` when the list was edited first.

### 10.4 reflog

A destructive reset yanks a label back; the reflog still lists the commits; a rescue brings them back.

| Parameter | Default | Effect |
|---|---|---|
| `on X` (words) | `main` | the branch |
| `commits=` | 4 | a number or a list of letters or real IDs (up to 8) |
| `back=` | 2 | how many commits the reset drops (the command reads `git reset --hard HEAD~N`; `cmd_reset=` words it yourself) |
| `rows=id:selector:text\|...` | three lines made from the commits | the reflog lines, up to five (`rows=589d18b:HEAD@{0}:reset:_moving_to_HEAD~1\|...`) |
| `hl=` | 1 | which line is found (0 is the first) |
| `reflog_of=feat/rerank` | | the panel's command reads `git reflog feat/rerank` |
| `lost=reflog` | `ghost` | how the dropped commits are drawn: `reflog` is correct for commits a reflog still names (dashed, not faded); `ghost` is what batch one shows |
| `note=` | "no label points here" / "only the reflog names it" | the words under the lost tip |
| `rescue=branch`, `rescue_name=` | `reset` | the rescue: `reset` moves the label back (`git reset --hard HEAD@{1}`), `branch` puts a new branch (`rescue`) on the commit, `none` only finds it |

Steps: `setup`, `reset`, `reflog`, `rescue`.

```text
**[ANIMATION]** reflog: on feat/rerank commits=8afc6bd,589d18b,5ee19f0,af65a92 back=1 lost=reflog rescue=branch rescue_name=rescue/rerank
```

Use it when one reset and one rescue are the story. Do not use it when the loss comes from something else (a bad rebase, an amend): write that as a `graph` with `reflog:` and special refs such as `HEAD@{1}`.

### 10.5 trees

Working tree, index and HEAD as three boxes; a file's content flows between them.

| Parameter | Default | Effect |
|---|---|---|
| `file=config/settings.yaml` | `app.py` | the path on the cards and in the commands (a long path shrinks, then breaks after a directory) |
| `names=a,b,c`, `subs=a,b,c` | Working tree, Index, HEAD; files on disk, the staging area, the last commit | the three boxes and their subtitles, always in the order working tree, index, HEAD |
| `order=reverse` | working tree on the left | HEAD on the left, as the drawings of sections 2.9 and 4.4 do |
| `versions=a,b,c` | version 1, version 2, version 3 | the words on the version chips |
| `chips=a,b,c` | | what each box holds at the start when the three do not agree (a conflicted merge) |
| `state=2,2,1` | 1,1,1 | the version each box starts with (working tree, index, HEAD): start after an edit, after an add ... |
| `in=wt` / `in=wt,index` / `in=index,head` | all three | the boxes that hold the file at the start. `in=wt`: a new, untracked file; `in=index,head`: a sparse checkout |
| `absent=not_on_disk` | "not here" | the words in a box that does not hold the file |
| `badges=-,skip-worktree,-` | none | a flag on a file card (working tree, index, HEAD; `-` for none) |
| `forms=CRLF,LF,LF` | none | the form the content has in each box (line endings, a clean or smudge filter); `-` for none |
| `forms_<step>=LF,LF,LF` | | the forms after that step (`forms=CRLF,-,LF forms_add=CRLF,LF,LF`): the pills change when the step's own motion ends |
| `ref=main` | a bare `HEAD` chip | the branch (with `HEAD` beside it) under the history |
| `commits=f7c044e,2da8d74` | `c1`, `c2` | the IDs under the two commits; `commits=f7c044e`: one ID (the second commit has none); `commits=none`: "no commit yet", and the `commit` step makes the first one |
| `history=off` | on | no history strip under the HEAD box |
| `merge=on` | off | the commit made by `commit` is a merge commit with two parents |
| `reset=soft\|mixed\|hard` | `hard` | what the `reset` step does |
| `safe=restore` | none | steps that are not drawn as destructive (a restore that overwrites nothing) |

Steps: `setup`, `edit`, `add`, `commit`, `restore`, `reset`. Only with `steps=`: `edit2` (a second edit after add), `unstage` (`git restore --staged`), `restore-source` (`git restore --source=HEAD`), `commit-a`, `forget` (`git rm --cached`: the index entry is gone, the file stays), `reset-soft`, `reset-mixed`, `reset-hard` (played one after the other they show the three modes on one commit).

```text
**[ANIMATION]** trees: file=config.yaml state=2,2,1 commits=f7c044e,2da8d74 ref=main steps=setup,commit,reset-soft,reset-mixed,reset-hard
```

Use it when the question is "where is this version of the file now?". Do not use it when several files matter (`walk`, or a terminal), or for two worktrees (`stores`).

### 10.6 remotes

The six-step story: your clone, origin, a teammate. Any other story between repositories is written in the graph notation with panels (section 9); the scene name stays `remotes`.

| Parameter | Default | Effect |
|---|---|---|
| `with Asha` (words), `teammate=` | "teammate" | names the teammate; `solo` or `teammate=none` draws only your clone and origin (the teammate's commits arrive from outside the picture) |
| `branch=` | `main` | the branch |
| `ids=a,b,c,d` | letters | the commits (real short IDs are drawn under the commits) |
| `start=` | 2 | how many commits every repository has at the beginning |
| `incoming=` | 1 | how many commits the teammate pushes (up to 3). `incoming=0`: none, so that `steps=setup,commit,push` leaves no gap |
| `names=laptop,origin,CI_clone` | your clone, origin, Asha's clone | the titles of the boxes |
| `note=a_bare_repository_on_disk` | "the shared server" | the grey words beside "origin" |

Steps: `setup`, `teammate-push`, `fetch`, `pull`, `commit`, `push`.

```text
**[ANIMATION]** remotes: solo incoming=0 steps=setup,commit,push ids=95671d3,510ee94,ef22149
```

Use the six-step form when that is the story; use the panel form for a rejected push, a forced update that orphans commits (`ghost:`), `pull --rebase`, tags that travel, a second branch, a fork, a CI clone, a bundle as a third box.

### 10.7 objects

Commit, tree, blobs, and two snapshots sharing blobs; or, with `cards=`, any objects as cards.

| Parameter | Default | Effect |
|---|---|---|
| `commits=a,b`, `trees=a,b`, `messages=a,b` | sample values | the two commits, their trees and messages |
| `files=name:id>newid,name:id` | three sample files | two to four files; `>` marks the file that changes and its new blob |
| `cards=kind:id:row+row,kind:id:row` | | **any objects**: cards separated by commas (or `\|`), rows by `+`. Kinds: `commit`, `tree`, `blob`, `tag`. A row that contains the ID of another card points at it; the cards stand in up to three columns by distance from the cards nothing points at. Up to nine cards |
| `refs=tag:v1.0>id,main>id` | | names above a card (with `cards=`): a branch, or `tag:name` for the tag shape. An annotated tag points at a `tag` card, a lightweight tag straight at the commit |
| `missing=id,id`, `damaged=id` | | cards that are not in this repository (a blob a partial clone left out), or damaged |
| `signed=id:1-4`, `signed_text=` | none; "signed" | a green bar beside rows 1 to 4 of that card and a legend under it: what a signature covers |

Steps: `commit`, `tree`, `blobs`, `second-commit`, `shared`, `compare`; with `cards=`: `level-1`, `level-2`, `level-3` (one per column).

```text
**[ANIMATION]** objects: cards=tag:131e7a7:object_20cd723+type_commit+tag_v1.0,commit:20cd723:tree_e223878+parent_51d62b3,tree:e223878:100644_blob_98a743c_README.md+040000_tree_27bb9f5_src,tree:27bb9f5:100644_blob_257376b_app.py,blob:98a743c:#_Ticket_router,blob:257376b refs=tag:v1.0>131e7a7,main>20cd723 missing=257376b
```

Use it when the lesson is what an object contains and points at. Do not use it for history (`graph`) or for where objects are stored (`stores`).

### 10.8 hash

The ID is computed from the content: same content, same ID; one difference, another ID.

| Parameter | Default | Effect |
|---|---|---|
| `differs=byte\|date\|parcel` | `byte` | the sample story: a file on two machines; the same commit made at two times; the warehouse analogy |
| `left=`, `right=` | by story | the titles of the two cards |
| `lines=a,b,c` | by story | the content, up to eight lines (use `\|` between lines that contain commas) |
| `change=3` | the last line | which line differs on the second card |
| `alt=` | by story | that line as it reads on the second card |
| `ids=first,second` | sample IDs | the two IDs; one value is enough when only `one` and `same` play. IDs longer than 16 characters (40 or 64 digits, an SSH fingerprint) are set on two lines |
| `fn=`, `fn2=` | `hash` | the word in the pill; `fn2` is another function on the second card: the same content, two functions, two IDs (no line is highlighted) |
| `badge=binary` | | a word on both cards |
| `same=`, `diff=` | by story | the two captions |

Steps: `one`, `same`, `different`.

```text
**[ANIMATION]** hash: differs=byte lines=tree_29b0184|parent_d4c9fab|Add_scorer,_first_version fn=SHA-1 fn2=SHA-256 ids=1442f02427f21cdc85e98b91d69535929f65e7ab,02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de steps=one,different
```

Use it for "the name is computed from the content". Do not use it for where the object is stored.

### 10.9 sandbox

Your real setup and the lab sandbox as two boxes; lab commands bounce off the real one.

| Parameter | Default | Effect |
|---|---|---|
| `name=` | "The lab sandbox" | the title of the lab box |
| `real=a,b,c` | `~/.gitconfig`, your repositories, your credentials | the three lines in the "Your real setup" box |
| `inside=a,b,c` | its own Git configuration, a clock the replays control, one directory per replay | the three lines in the lab box |

Steps: `room`, `inside`, `outside`, `enter`, `doors`, `shield`. In a one-paragraph scene add `pace=quick`, or the boxes arrive spread over the whole paragraph.

```text
**[ANIMATION]** sandbox: steps=room,inside,outside name=The_gate_sandbox pace=quick
```

### 10.10 flow

A sequence between two to five actors, one message per step: a credential helper, an authentication path and where it fails, a token exchange, the wire conversation of a fetch.

| Parameter | Default | Effect |
|---|---|---|
| `actors=a,b,c` | required | the actors from left to right; `*name` draws one in the accent colour. A name too long for its box takes two lines |
| `subs=a,b,c` | none | a second line under each name (`-` for none) |
| `msgs=1>2:label\|2>1:label:ok\|3>1:401:fail\|2>2:a_note` | required, up to 8 | the messages in order: `from>to:label:mark`, with the actors' numbers. The same number twice is a note on that actor. Marks: `ok`, `fail` (the arrow turns red: this is where it fails), `wait` |
| `boundary=2`, `zones=left,right` | none | a dashed line after that actor (a trust boundary, the network) and the names of the two sides |
| `mono=on` | off | labels in Menlo (protocol words, commands) |

Steps: `actors`, then `1`, `2` ... one per message.

```text
**[ANIMATION]** flow: actors=Git,credential_helper,*the_server msgs=1>2:get|2>1:username_+_token|1>3:request_with_the_token|3>1:401_Unauthorized:fail|1>2:erase boundary=2 zones=your_machine,the_network title=Where_HTTPS_authentication_fails
```

A note (the same number twice) that would leave the frame beside the first or last actor moves inward. A label between two neighbouring actors has one line: with five actors keep it under about 18 characters.

Use it when order and direction matter. Do not use it when the parties hold things that stay (`stores`), or when one object passes checkpoints (`gates`).

### 10.11 gates

One thing travels along a line of checkpoints; each can pass it, stop it, be skipped, be bypassed, or make it wait. After a stop the remaining gates fade: they are never reached.

| Parameter | Default | Effect |
|---|---|---|
| `gates=name:verdict:owner:note\|...` | required, up to 7 | verdicts: `pass`, `stop`, `skip`, `bypass`, `wait`, `done`. `owner` stands under the gate (`-` for none), `note` appears when the gate is reached (what it can stop, why it stopped). With many gates the texts wrap: a name takes up to three lines, an owner two, a note four (with seven gates a line holds about 12 characters) |
| `packet=text` | none | what travels (a ref update, a push) |
| `zones=a,b`, `split=2` | none | two bands behind the gates (your machine, the server); the first `split` gates belong to the first |
| `result=text` | none | the words at the end of the line; adds the step `result` |

Steps: `setup`, `1`, `2` ... one per gate, (`result`).

```text
**[ANIMATION]** gates: packet=git_push_origin_main gates=pre-commit:pass:client:can_stop_the_commit|pre-push:pass:client:can_stop_the_push|pre-receive:stop:server:can_refuse_every_ref|post-receive:skip:server:cannot_stop_anything zones=your_machine,the_server split=2 result=!_[remote_rejected]
```

Use it for hooks, for the rules a push meets one after the other, for a fixed sequence of stages (`done` for each). Do not use it when the checks are judged together and add up (`layers`).

### 10.12 bisect

The halving, as a commit graph with marks: the range that is left is shaded, the commit under test carries HEAD, what is ruled out goes dark.

| Parameter | Default | Effect |
|---|---|---|
| `commits=16` or `commits=id,id,...` | 12 | the commits (a number: letters up to 26, then `c1`, `c2` ...) |
| `good=`, `bad=` | the first and the last | an ID or a position |
| `first_bad=11` | the middle | the answer, as an ID or a position; the scene works out the tests |
| `tests=id:good\|id:bad\|id:skip` | worked out | the tests of the transcript, in order, when Git chose other commits than the plain middle. A `skip` gets the amber mark and the command `git bisect skip`; the range does not shrink. The scene ends on the last commit marked bad |
| `skip=id,id` | none | commits that carry the `skip` mark from the `start` step on (`git bisect skip` before the first test) |
| `counts=off` | the scene counts | no "N left" anywhere: not on the shaded range, not in a caption |
| `counts=20,10,10,5,2` | the scene counts | the numbers of your transcript, for `start`, `mark-1`, `mark-2` ... (`-` or a missing value: none at that step). Use it whenever the transcript has a skip or Git's own choices: the scene's count is the number of commits between the last good and the last bad one, and Git's "revisions left to test" is another number |
| `say_<step>=text`, `cmd_<step>=text` | the scene's wording | the caption or the command of one step: `say_test_2=Git_picks_a_neighbour_of_the_skipped_commit`, `say_found=...`, `say_mark_1=off` |

Steps: `grow`, `start`, then `test-1`, `mark-1`, `test-2`, `mark-2` ..., `found`.

The scene's own captions: `start` "One of these N commits introduced the bug"; `test-k` "Git checks out the middle of what is left: X" (with `tests=`: "Git checks out X", because Git's choice need not be the middle); `mark-k` "X is good: N left" (a skip: "X cannot be tested: Git picks a neighbour"); `found` "X is the first bad commit, found in K tests instead of M" (with `counts=`: "X is the first bad commit"). Anything a transcript contradicts is replaced with `say_<step>=`.

```text
**[ANIMATION]** bisect: commits=16 first_bad=11

**[ANIMATION]** bisect: commits=21 good=A bad=U tests=K:good|P:skip|Q:bad|N:bad|M:good counts=20,10,10,5,2,1 say_test_3=Git_picks_a_commit_next_to_the_skipped_one
```

Do not use it for the exit-code protocol of `git bisect run` (a terminal, or `walk`).

### 10.13 stash

A stash entry as two commits on top of HEAD, with `refs/stash`; after a pop nothing names them.

| Parameter | Default | Effect |
|---|---|---|
| `commits=a,b` | `A,B` | the history |
| `on X` (words), `branch=` | `main` | the branch |
| `index=`, `stash=` | `I`, `W` | the IDs of the index commit and of the stash commit |
| `pop=off` | on | no `pop` step |

Steps: `grow`, `state-1`, `stash`, `pop`. For `stash@{1}` or an autostash write the graph yourself (`special:stash@{1}`).

```text
**[ANIMATION]** stash: commits=6eab4a9,23b0907 index=3dfab55 stash=f5192c8 on main
```

### 10.14 tags

A lightweight tag points at a commit; an annotated tag points at a tag object first.

| Parameter | Default | Effect |
|---|---|---|
| `commits=a,b,c` | `A,B,C` | the history |
| `light=name@commit` | `v0.9` on the commit before the last | the lightweight tag |
| `annotated=name@commit#tagid` | `v1.0` on the last commit | the annotated tag and the ID of its tag object |

Steps: `grow`, `state-1`, `lightweight`, `annotated`. A tag that differs between two clones: panels (section 9), with the same tag name in both.

```text
**[ANIMATION]** tags: commits=d4c9fab,bb904cd,191bbd1 light=v0.9@bb904cd annotated=v1.0@191bbd1#131e7a7
```

### 10.15 layers

Layers stacked one under the other, each with its items, and what they add up to.

| Parameter | Default | Effect |
|---|---|---|
| `layers=name:item+item\|name:item` | required, up to 6 | the layers from top to bottom |
| `probe=text` | none | what is being judged, drawn above (a push, a merge, a user) |
| `verdicts=pass,fail,bypass` | none | a mark at the end of each layer |
| `result=item+item`, `rule=words` | none; "together" | the bar at the bottom: what the layers add up to, and the words in front of it; adds the step `result` |
| `winner=2` | none | that layer wins and the others fade ("highest grant wins", "the nearest file wins"); the result bar shows its items unless `result=` says otherwise |

Steps: `1`, `2` ... one per layer, (`result`).

```text
**[ANIMATION]** layers: probe=merge_into_main layers=organization_ruleset:block_force_pushes+1_approval|repository_ruleset:signed_commits+3_approvals|classic_rule_on_main:linear_history verdicts=pass,fail,pass result=no_force_push+signed_commits+linear_history+3_approvals rule=a_merge_must_satisfy
```

Use it for rulesets, permission levels, configuration or attribute precedence, "Git data inside a platform" as two layers. Do not use it when the checks happen in order and the first failure ends it (`gates`).

### 10.16 stores

Boxes that hold things; rows arrive and arrows are drawn step by step.

| Parameter | Default | Effect |
|---|---|---|
| `boxes=title:sub\|title:sub` | required, 1 to 4 | the boxes from left to right (letters A to D); `*title` in the accent colour. A long title or sub-line takes two lines |
| `rows=step:box:text\|...` | | a row arrives in that box at that step. `@hl`, `@ok`, `@bad`, `@dim`, `@ghost`, `@ref` after the text set its style. Up to 7 rows in a box. A row too long for its box (a path, a command) is set in two or three lines, broken at a space or after `/ _ - .`; with four boxes a line holds about 17 characters in Menlo (13 when there are arrows), so a row can hold about 40. A semicolon may stand in a row |
| `arrows=step:A1>B2:label\|...` | | an arrow at that step from row 1 of box A to row 2 of box B (a letter alone: the box); an arrow that skips a box goes over the top. A label stands in the gap between the two boxes: a long one takes two lines and the gap widens for it (the boxes get narrower), up to about 20 characters with three boxes and 14 with four |
| `say_<step>=text` | none | a caption on the line under the title when that step plays (`say_1=One_repository,_three_working_trees`); a `say:` tag does the same while the scene is held |
| `mono=on` | off | rows in Menlo |

Steps: `boxes`, then `1`, `2` ... up to the highest step number.

```text
**[ANIMATION]** stores: boxes=working_tree:what_you_edit|*Git_repository:.git/objects|LFS_store:.git/lfs/objects rows=1:A:model.bin_(2_GB)|2:B:pointer_file_(134_bytes)@hl|2:C:the_2_GB_of_content|3:A:model.bin_again@ok arrows=2:A1>B1:clean_filter|2:A1>C1:bytes|3:C1>A2:smudge_filter
```

Use it for worktrees (two working trees, one repository), Git LFS, loose objects becoming a pack with a base and deltas, a bundle (header, prerequisite, pack), two `.git` layouts side by side, a fork network (two sets of refs, one object store), the reach of a token. Do not use it when the things are commits with parents (`graph`, panels).

### 10.17 match

A list of patterns and the paths asked about; the matching lines light up one after the other and the winner stays lit. The script says which lines match; the scene does not evaluate patterns.

| Parameter | Default | Effect |
|---|---|---|
| `header=.github/CODEOWNERS` | "rules" | the title of the list |
| `rules=pattern:value\|pattern:value` | required, up to 8 | the lines: a pattern and what it gives (owners, attributes, a file to include, an identity) |
| `numbers=2,5,6` | 1, 2, 3 ... | the line numbers to print |
| `paths=path:1+2\|path:1+2+4\|path:` | required, up to 5 | the paths asked about, each with the numbers (positions in `rules=`) of the lines that match; none: nothing matches |
| `wins=last\|first\|all` | `last` | which matching line wins |
| `none_text=` | "no match" | what a path gets that nothing matches |

Steps: `rules`, then `1`, `2` ... one per path.

```text
**[ANIMATION]** match: header=.github/CODEOWNERS rules=*:@example-org/platform|/router/:@example-org/routing|*.yaml:@example-org/sre paths=router/classify.py:1+2|router/rules/eu.yaml:1+2+3 wins=last
```

Use it for CODEOWNERS (last match wins), `.gitattributes`, `.gitignore`, `includeIf` routing from a directory to an identity, `~/.ssh/config` (first match wins: `wins=first`).

### 10.18 blame

The lines of a file, each with the commit that last changed it; a second attribution shows what `-w`, `-M` or an ignored revision change.

| Parameter | Default | Effect |
|---|---|---|
| `file=` | "file" | the title of the card |
| `lines=id:text\|id:text` | required, up to 9 | the lines; underscores at the start of a line are its indentation, one space each. Inside a line the underscore rule holds, read for code: three underscores before a letter or a digit are a space and the underscore of a name (`x_=___private` is `x = _private`) |
| `indent=4` | every leading underscore is a space | the file is indented in steps of 4 (or 2, 8 ...): only whole steps at the start of a line are indentation, and what is left over follows the underscore rule. With it a line can **begin with an underscore**: `__NAME_=_1` is `_NAME = 1`, `______name` is four spaces and `_name`. (Without `indent=` those would be two and six spaces. The older way still works: a zero-width space in front of the underscores) |
| `from=41` | 1 | the number of the first line |
| `after=id,id,...` | none | the commit of every line in the second attribution; adds the step `after` (changed lines light up, the others fade) |

Steps: `file`, `blame`, (`after`).

```text
**[ANIMATION]** blame: file=router/classify.py lines=53e7f57:def_classify(ticket):|9aa221a:____threshold_=_0.7|b4554be:____return_"high" after=53e7f57,9aa221a,53e7f57

**[ANIMATION]** blame: file=scorekit/text.py from=5 indent=4 lines=9c8df982:__PUNCTUATION_=_re.compile(r"[^\w\s]")|dd70d9e4:def_normalize(text):|9c8df982:____return___PUNCTUATION.sub("",_text)
```

### 10.19 todo

The todo list of an interactive rebase as Git writes it and as you leave it: lines move, verbs change, a dropped line is struck out.

| Parameter | Default | Effect |
|---|---|---|
| `todo=verb:id:subject\|...` | required, up to 8 | the list as Git writes it. A verb with an option is written `fixup_-C:614c93b:subject` (or `fixup:-C_614c93b:subject`): it is drawn as `fixup -C` in the colour of `fixup` |
| `edit=verb:id:subject\|...` | none | the list after editing: the new order and the new verbs; a line left out is dropped. Adds the step `edit` |
| `result=a,b` | none | the commits the rebase will make (words or IDs); adds the step `result` |
| `file=` | `git-rebase-todo` | the title |

Steps: `list`, (`edit`), (`result`). Follow it with a `rebase` or a `graph` scene for what the rebase then does.

```text
**[ANIMATION]** todo: todo=pick:1edd58e:Add_parser|pick:614c93b:Fix_typo_in_parser|pick:266d3b2:Add_tests edit=pick:1edd58e:Add_parser|fixup:614c93b:Fix_typo_in_parser|reword:266d3b2:Add_tests result=Add_parser,Add_tests
```

### 10.20 push

A push in parts: a refspec maps a local name to a remote name, your own Git judges the update, the server judges it, a lease compares what you expected with what is there.

| Parameter | Default | Effect |
|---|---|---|
| `src=`, `dst=` | `main`, the same | the local and the remote name as they stand in the two boxes |
| `refspec=` | `src:dst` | the text on the wire |
| `names=a,b` | your repository, the remote | the titles of the boxes |
| `local=id`, `remote=id` | none | the commit you push and the commit the remote ref points at now (after a successful push the remote shows the pushed one) |
| `gates=a,b` | "your Git: a fast-forward?", "the server: hooks and rules" | the two gatekeepers. One whose step is left out with `steps=` is not drawn (`steps=refspec,result`: no gatekeepers at all) |
| `client=pass\|stop`, `server=pass\|stop\|skip` | `pass` | their verdicts |
| `notes=a,b` | none | what each gatekeeper says |
| `lease=expected,actual` | none | adds the step `lease`: three columns (expected, actual, verdict); different values refuse the push. `lease_names=a,b,c` renames the columns |
| `result=text` | "the remote ref moves" / "the push is rejected" | the last line |

Steps: `refspec`, `client`, `server`, (`lease`), `result`.

```text
**[ANIMATION]** push: src=main dst=main refspec=refs/heads/main:refs/heads/main local=810dc2f remote=4e1f5fe client=pass server=stop notes=the_new_tip_contains_the_old_one,rule:_block_force_pushes result=!_[remote_rejected]_main_->_main
```

### 10.21 ladder

How far a commit has fallen, and what still brings it back at each rung. `rungs=state:how\|...` (default: reachable, only in the reflog, unreachable, pruned, with Git's own way back for each), `commit=` (the ID of the commit that descends). Steps: `1`, `2` ... one per rung.

```text
**[ANIMATION]** ladder: commit=af65a92
```

### 10.22 walk

A table that is read row by row.

| Parameter | Default | Effect |
|---|---|---|
| `columns=a,b,c` | none | the column heads; an empty one keeps its column (`columns=,base,ours` or `columns=-,base,ours`) |
| `rows=cell:cell:cell\|...` | required, up to 9 | the rows. When the table is too wide for the frame the cells take the smallest size, then the widest columns wrap: three lines per cell with up to four rows, two with five or six, one with more |
| `marks=1.5:ok,4.5:bad` | none | the colour of single cells (`row.column`): `ok`, `bad`, `wait`, `hl`, `dim` |
| `pick=4` | none | that row is the answer: it is outlined and the others fade; adds the step `pick` |
| `last=result` | | the last column head in the second accent colour |
| `mono=off` | cells in Menlo | cells in the text face |

Steps: `header`, then `1`, `2` ... one per row, (`pick`).

```text
**[ANIMATION]** walk: columns=file,base,ours,theirs,result rows=config.yaml:v1:v2:v1:ours_(v2)|router.py:v1:v1:v3:theirs_(v3)|rules.yaml:v1:v2:v3:CONFLICT marks=1.5:ok,2.5:ok,3.5:bad last=result
```

Use it for base / ours / theirs / result at file level, a lease check, the rows of a listing (a pack, a Bloom filter, a token table). Do not use it for a table that is only shown: a Markdown table in the script already reveals its rows.

### 10.23 decide

A decision tree with its own questions and leaves, or (as `lifecycle:` or `states:`, or with `reveal=edges`) a state diagram whose transitions are drawn one per step.

| Parameter | Default | Effect |
|---|---|---|
| `nodes=id:text\|id:text` | required, 2 to 12 | the nodes; the first is the root. A node without an outgoing edge is a leaf |
| `edges=a>b:label\|...` | required | the edges with their answers or events; a long label takes up to three lines (about 11 characters each between three columns) |
| `path=q1,q2,a` | none | the way taken: it lights up and the rest fades; adds the step `path` |
| `grid=id:column.row,...` | worked out from the edges | the place of a node, for a state diagram that should read well: `grid=draft:1.1,open:2.1,closed:2.2` |
| `reveal=edges` | `levels` | one step per edge instead of one per column |

Steps: `level-1`, `level-2` ..., (`path`); with `reveal=edges`: `nodes`, then `1`, `2` ... one per edge.

```text
**[ANIMATION]** decide: nodes=q1:Was_the_work_ever_committed?|q2:Does_a_branch_still_reach_it?|a:git_log_finds_it|b:git_reflog,_then_git_branch|d:not_in_Git edges=q1>q2:yes|q1>d:no|q2>a:yes|q2>b:no path=q1,q2,b
```

Keep a state diagram to about six states, and give it a `grid=`.

### 10.24 bars

A few numbers as bars, one per step. `bars=label:value\|...` (up to 8), `unit=MB`, `max=` (the value of a full-height bar). Steps: `1`, `2` ...

```text
**[ANIMATION]** bars: bars=after_clone:412|after_100_commits:498|git_gc:96 unit=MB title=Pack_sizes
```

### 10.28 cards

A few statements as cards, one per step: the answers to a question, the conditions of a rule, the options of a quiz. Afterwards some are ticked, crossed, locked, ringed or dimmed.

| Parameter | Default | Effect |
|---|---|---|
| `cards=text:sub-line\|text\|...` | required, up to 8 | the cards (three or fewer in one row, then two rows) |
| `question=` | none | one or two lines above the cards |
| `numbered=on` | off | a number on each card |
| `dim=4,5` | none | these cards arrive dimmed ("the next video covers these") |
| `ask=6` | none | this card arrives dashed with a question mark, until a mark resolves it |
| `marks=1:ok,2:ring,6:lock` | none | adds the step `marks`: `ok` (tick), `bad` (cross), `lock`, `ring`, `dim`, `solid` |

Steps: `1`, `2` ... one per card, (`marks`).

```text
**[ANIMATION]** cards: question=How_did_the_change_merge? cards=No_rule_required_the_review|A_later_line_took_the_path_away|The_pull_request_was_a_draft dim=3 numbered=on marks=1:ok,2:ring
```

Use it when the narration lists a few short statements and returns to them. Do not use it for a plain list that is only read once: a Markdown list in the script already arrives item by item.

### 10.25 pr

The pull request flow as five stages, a small commit graph and a card.

| Parameter | Default | Effect |
|---|---|---|
| `X into Y` (words) | `feature` into `main` | the branches |
| `number=7` / `number=off` | 42 | the number on the card, or none |
| `base_ids=a,b`, `commits=` | letters; 2 | the two commits on the base branch, and the commits of the branch (a number, or up to four IDs) |
| `merge_id=`, `late_id=` | `M`; the next letter | the commit the merge makes; the commit of step `push-again` |
| `letters=off` | on | no letters or IDs in the circles |
| `review=approved\|missing\|changes\|unknown\|off` | `approved` | the state of the review row; `off`: no review row |
| `review_text=` | by state | the words of the review row |
| `approvals=2/3` | | the review row reads "2 of 3 approvals" and is green only when the two numbers agree |
| `checks=passed\|failing\|pending\|unknown` | `passed` | the state of the checks; the word `blocked` alone means review and checks unknown |
| `check_names=a,b,c` | tests, lint | one to four check rows |
| `check_states=passed,skipped` | from `checks=` | a state per row (`skipped`: an open amber ring that keeps the merge blocked) |
| `method=merge\|squash\|rebase` | `merge` | what lands on the base branch: a merge commit, one new commit with one parent, or copies of the commits |
| `block=Rule:_conversations_must_be_resolved` | none | a further row that refuses the merge although the review and the checks are green: the scene ends BLOCKED |
| `layers=on` | off | a small pill on each part: Git, GitHub, GitHub Actions |
| `cmd=off` | on | hides `git switch -c` and `git push -u` in a video that does not teach them |

When the review or a check is not green, the `merge` step draws no merge commit: the last stage gets a red cross and the card a BLOCKED stamp.

Steps: `branch`, `push`, `review`, `checks`, `merge`. Only with `steps=`: `push-again` (a commit pushed after the review), `dismissed` (the approval is withdrawn), `re-approve`.

```text
**[ANIMATION]** pr: feature/priority into main number=off review_text=Review:_1_approval_required check_names=ci,lint,build commits=44c1e7b,12ae95d,16d4788 base_ids=9a383e5,9aa221a merge_id=da48bba method=squash title=Squash_and_merge
```

Use it for the flow as a whole. Do not use it for the life cycle as states (`lifecycle:`), for which rules block a merge (`layers`, `gates`), or for what three merge methods leave on the base branch side by side (`methods`).

### 10.26 ci

A CI run end to end: event, workflow, runner, steps, result.

| Parameter | Default | Effect |
|---|---|---|
| the event as a word, or `event=` | `push` | `push`, `pull_request`, `schedule`, `workflow_dispatch`, `release`, `merge_group`: the chip, the `on:` line and the first caption |
| `trigger=`, `subject=` | by event | the caption's words for the trigger; the word under the commit circle |
| `(checkout, install, test)` | four sample steps | the steps of the job, up to five |
| `file=`, `job=`, `runner=` | `ci.yml`, `test`, `ubuntu-latest` | the names on the picture; `off` hides one |
| `result=failed` | green | the run ends red: a cross on the last step and on the result |
| `result=skipped`, `skip_text=` | | no run starts (a path filter did not match): the steps `runner` and `steps` draw nothing and the result is an open amber ring. `skip_text` words the reason |

Steps: `event`, `workflow`, `runner`, `steps`, `result`.

```text
**[ANIMATION]** ci: merge_group result=skipped file=off job=off runner=off skip_text=paths:_docs/**_did_not_match steps=event,workflow,result
```

Use it for "what happens when a run starts". For jobs that need each other, a matrix, permissions, caches, environments: `run`.

### 10.27 run

One workflow run in detail. Nothing is drawn that the tag does not name.

| Parameter | Default | Effect |
|---|---|---|
| `event=`, `ref=`, `sha=` | `push`; none | the event, the ref and the commit the run runs on |
| `jobs=lint\|test\|build:lint+test\|deploy:build` | required, up to 8 | the jobs and what each needs; they stand in columns by their needs |
| `matrix=test:3.11+3.12+3.13` | none | one job fans out (up to four legs); adds the step `matrix` |
| `token=contents:read+id-token:write` | none | the permissions of the run's token; adds the step `token` |
| `artifact=build>deploy:dist`, `cache=test:uv_cache` | none | an artifact that travels between two jobs, a cache a job restores and saves; either adds the step `data` |
| `env=deploy:production:a_required_reviewer` | none | a job waits at an environment's gate for a reviewer; adds the step `gate` |
| `concurrency=deploy-main` | none | an older run of that group is cancelled; adds the step `cancel` |

Steps: `event`, `jobs`, (`matrix`), (`token`), (`data`), (`gate`), (`cancel`).

```text
**[ANIMATION]** run: event=pull_request ref=refs/pull/7/merge sha=135aad1 jobs=lint|test|build:lint+test|deploy:build matrix=test:3.11+3.12+3.13 token=contents:read artifact=build>deploy:dist env=deploy:production:a_required_reviewer
```

## 11. For the maintainer

- The scenes are in `tools/anim/scenes.js` (the scenes of batch one, generalized), `tools/anim/scenes2.js` and `tools/anim/scenes3.js` (the schematic and topic scenes); the tag parser, the graph notation, the presets (`bisect`, `stash`, `tags`) and the cue timing in `tools/video_animplan.py`.
- `video/production/make.sh demo` builds a video that plays every scene and every generalization once (the script is `tools/anim/demo/V000-the-animation-library.md`). The self-test takes its sample tags from that script: every scene must be in it.
- `python3 tools/video_animtest.py --compat` compares the planner with the library as it was when batch one was approved ("v1", frozen in `tools/anim/compat/`): every tag, every drawing and every storyboard plan of that moment must come out the same. `--compat pictures` draws every scene picture of the frozen storyboards with the frozen JavaScript and with the current one and compares the frames byte for byte; `--compat motion` does the same for every frame of every scene clip of batch one and of the demo.
- The layout check (`Scenes.lint` in `scenes.js`; `--look` and section c of the self-test run it on every state) reports text that is too small, cut short, cut off at the edge, or on other text. A scene that cuts a text registers it with `Scenes.cut(shown, full)`; `fit`, `wrap` and `wrapW` in `scenes2.js` do so themselves. The check also returns every visible text and the outline of every visible circle, which the self-test uses for the cases of `FIX_TAGS` in `tools/video_animtest.py` (one sample tag per reported defect); `SCRIPT3` and `fixes_planner()` there hold the cases the planner decides.
- A warning that would change what the storyboard reports for the scripts of batch one goes into the storyboard's `hints` list instead of `warnings` (printed in the same way): the frozen comparison covers `warnings`.
- The type sizes: the schematic scenes use 28 units or more (about 26 px on the 1080p frame). The scenes of batch one keep their approved sizes: card text of 22 to 26 units, commit IDs of 21 units in a graph, which the camera shows larger or smaller. Keep a graph with real IDs to about ten commits in a row, or to six per panel with three panels side by side.
- The three pilot scripts V001, V007 and V030 show the tags in real use; V002 (a blocked pull request), V003 (renamed boxes, a real path, a branch under the history), V020 (a real merge in the graph notation), V022 (one graph in three states) and V033 (special refs) show the parameters of batch one.
