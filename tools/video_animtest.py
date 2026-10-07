#!/usr/bin/env python3
"""Self-test of the animation layer.  Run by tools/video_selftest.py (section 6), or on its own:

    python3 tools/video_animtest.py

It works in video/production/.cache/selftest/anim with a small script of its own, so no course file is touched.

What it proves:
  a. the ASCII commit-graph parser reads the drawings it should and refuses the ones it should not;
  b. the [ANIMATION] tag vocabulary: every scene name parses, an unknown tag does not, a script without tags gets no scenes;
  c. the scene library in JavaScript has the same scenes and step names as the storyboard builder expects, and every
     scene draws without a JavaScript error;
  d. rendering is repeatable: the same page rendered twice gives byte-identical frames;
  e. a test video's clips: none failed, each file holds exactly the frames the page announced (no missing frames), 1920x1080, 30 fps;
  f. the timeline: every frame of the video belongs to exactly one segment;
  g. the finished MP4: 1920x1080, 30 fps, H.264 + AAC, the expected number of frames, audio and video equal within 0.1 s,
     and as long as the narration;
  h. the pronunciation table changes what is spoken (".git" -> "dot git") and nothing else;
  i. backward compatibility of the planner: every [ANIMATION] tag, every ASCII graph and every storyboard plan that
     existed when the library was frozen as "v1" still gives exactly the same result.

Backward compatibility in full (the frozen copy is tools/anim/compat/: the v1 JavaScript and the v1 planner results):

    python3 tools/video_animtest.py --compat                  the planner comparison of (i) alone, with details
    python3 tools/video_animtest.py --compat pictures [k/n]   every scene picture of the frozen storyboards, drawn by the
                                                              frozen v1 library and by the current one: the frames must be
                                                              byte-identical (k/n: only the k-th of n shares, for short runs)
    python3 tools/video_animtest.py --compat motion [k/n]     the same for every frame of every scene clip of batch one
    python3 tools/video_animtest.py --compat snapshot --force freeze the current library as the reference (only on purpose)
"""
import gzip, hashlib, json, os, pathlib, re, shutil, subprocess, sys, time

HERE = pathlib.Path(__file__).resolve().parent
COMPAT_MODE = "--compat" in sys.argv
LOOK_MODE = "--look" in sys.argv
TEST = HERE.parent / "video" / "production" / ".cache" / ("compat" if COMPAT_MODE else "look" if LOOK_MODE else "selftest/anim")
os.environ["VIDEO_WORK_DIR"] = str(TEST)
os.environ["VIDEO_SCRIPTS_DIR"] = str(TEST / "scripts")
os.environ["VIDEO_OUT_DIR"] = str(TEST / "out")
os.environ["VIDEO_RECORDINGS_DIR"] = str(TEST / "recordings")
os.environ["VIDEO_NARRATOR"] = "ai"
sys.path.insert(0, str(HERE))
from video_common import *        # noqa: E402,F401,F403
import video_animplan as AP        # noqa: E402
import video_storyboard, video_slides, video_animate, video_build   # noqa: E402

results = []


def check(name, ok, detail=""):
    results.append(bool(ok))
    print(f"  {'PASS' if ok else 'FAIL'}  {name}" + (f"   [{detail}]" if detail else ""), flush=True)
    return ok


G1 = """            5aec6e0---58a5e60   feature/rationale
           /
  6ae3c51---c089834             main   (HEAD -> main)
     ^
     merge base of main and feature/rationale"""
G2 = """  Before                                     After git merge feature/batch-size

  6ae3c51---23db174   feature/batch-size     6ae3c51---23db174   feature/batch-size
     ^                                                    ^
     main  (HEAD -> main)                                 main  (HEAD -> main)"""
G3 = """  d4c9fab---bb904cd---191bbd1-------------ae6795c   main   (HEAD -> main)
                  \\                       /
                   79ff6d7---59c914e-----+          feature/f1"""
NOT_GRAPHS = [""" +-------- your Mac --------+
 |  labs/shell   labs/run   |
 +--------------------------+""",
              """  A---B---C   main
       some words under the graph that point at nothing in particular""",
              "Observed behavior : nothing\nRoot cause        : none"]

SCRIPT = """# V000: Animation layer self-test

- **Part.** 3: Recovery
- **Planned minutes.** 1

## CONCEPT

**[ANIMATION]** rebase: topic onto main

A rebase lifts the commits of `topic`.

It copies them onto `main` and the label moves.

**[ANIMATION]** this tag is not a scene

## DIAGRAM

```text
  Before                 After git merge topic

  A---B   topic          A---B   topic
  ^                          ^
  main  (HEAD -> main)       main  (HEAD -> main)
```

Before, `main` is on commit A. After: the label has moved to B.

## LIVE TERMINAL DEMO

**[TERMINAL]** Caption bar: `labs/demo`.

<!-- snippet: demo/01-status -->
```text
$ git status --short
 M app.py
$ git log --oneline -1
a1b2c3d First commit
```
<!-- /snippet -->

First `git status --short` shows one modified file. Then `git log --oneline -1` shows the last commit.

## RECAP

After this video you can:

- Read a commit graph that grows.
- Say why a rebase makes new commits.

| Command | Risk |
|---|---|
| `git status` | none |
| `git reset --hard` | loses work |
"""


SCRIPT2 = """# V998: Held scenes

- **Part.** 3: Recovery
- **Planned minutes.** 1

## CONCEPT

**[ANIMATION]** graph: A-B main feature; HEAD=main => A-B-C feature; B main; HEAD=feature id=two point_state_2=C

**[ANIMATION]** step: state-1

Two names point at commit B.

**[ANIMATION]** say: Both names are on B

The caption changes while the picture is held.

**[ANIMATION]** hash: differs=byte

**[ANIMATION]** step: one

An ID is computed from content.

**[ANIMATION]** step: same

The same content gives the same ID.

**[ANIMATION]** twig: nod

Yes: that is the whole idea.

**[ANIMATION]** step: two.state-2

Back in the graph, a commit moves the current branch.

**[ANIMATION]** replay: hash

**[ANIMATION]** step: one

Once more from the start: one card, one ID.
"""


# A script for the defects reported from V034 to V088: at_<step>= on a graph, "end" and "replay:" before a drawing, "say:" that brings a
# scene back, a scene tag right after on-screen text, and steps called "1", "2" beside digits in the narration.
SCRIPT3 = """# V997: Library fixes

- **Part.** 3: Recovery
- **Planned minutes.** 1

## CONCEPT

**[ANIMATION]** graph: A-B main; HEAD=main => + A-B-C main; name:grown at_grown=40 id=g

**[ANIMATION]** step: state-1

The history has two commits and one name.

**[ANIMATION]** end

**[DIAGRAM]** The same history as a drawing.

```text
  A---B   main
```

The drawing is shown after the scene has left.

**[ANIMATION]** say: Still_two_commits,_and_no_ORIG__HEAD

The caption changes and nothing else.

**[ANIMATION]** step: grown

Some words come first, and only now a third commit arrives.

**[ANIMATION]** replay: g

**[DIAGRAM]** Once more.

```text
  A---B   main
```

This is read over the drawing.

## MENTAL MODEL

**[ON SCREEN]** "A quoted sentence on screen."

**[ANIMATION]** flow: actors=a,b msgs=1>2:x|2>1:y

Version 2 of the helper answers 1 question, and after that nothing more happens in this paragraph at all.
"""

# Sample tags for the same defects, drawn by the scene library; each has a check of what is on screen after its steps:
# T[k] = the visible texts after step k + 1, C[k] = "stroke-width/dash" of every visible circle (a commit, a mark ...).
_no = lambda T, word: not any(word in x for step in T for x in step)
FIX_TAGS = [
    ("graph: A-B-C main; HEAD=main => + B main; reflog:C; cmd:!git_reset_--hard_HEAD~1 => + cmd:off; say:off",
     'cmd:!... shows the warning triangle and the command without the "!"; cmd:off removes the command line',
     lambda T, C: "git reset --hard HEAD~1" in T[2] and "!" in T[2] and _no(T, "!git") and "git reset --hard HEAD~1" not in T[3] and "off" not in T[3]),
    ("trees: steps=setup,add cmd_add=!git_add_-A forms=CRLF,-,LF forms_add=CRLF,LF,LF",
     'cmd_<step>=!... does the same in another scene; forms_<step>= changes the forms with a step',
     lambda T, C: "git add -A" in T[1] and _no(T, "!git") and T[0].count("LF") == 1 and T[1].count("LF") == 2 and T[1].count("CRLF") == 1),
    ("blame: file=scorekit/text.py lines=9c8df982:__PUNCTUATION_=_1|dd70d9e4:|9c8df982:____text_=___PUNCTUATION.sub(text)|9c8df982:\u200b__ALL_=_2 indent=4 from=98",
     "blame: a line that starts with an underscore (indent=4, and the zero-width space as before); from= numbers the lines",
     lambda T, C: {"_PUNCTUATION = 1", "98", "101"} <= set(T[0]) and any(x.strip() == "text = _PUNCTUATION.sub(text)" for x in T[0]) and any(x.endswith("_ALL = 2") for x in T[0]) and "1" not in T[0]),
    ("graph: A-...-B-?the_Wednesday_copy main; A-C side; reflog:C; HEAD=none",
     "a bare ... before -id is an unnamed elision; a placeholder has a thin solid outline (the reflog style is dashed) and may be a long word",
     lambda T, C: "the Wednesday copy" in T[1] and "-B" not in T[1] and "2.5/none" in C[1] and "5/7 7" in C[1] and not any(c.startswith("2.5/") and c != "2.5/none" for c in C[1])),
    ("bisect: commits=8 tests=D:good|F:skip|G:bad counts=20,10,10,5 skip=E say_test_1=Git_checks_out_D",
     "bisect: counts= states the numbers, tests= may hold a skip, skip= marks a commit beforehand, say_<step>= words a caption",
     lambda T, C: "20 left" in T[1] and "skip" in T[1] and "Git checks out D" in T[2] and "10 left" in T[3] and "10 left" in T[5] and "5 left" in T[7] and _no(T, "middle of what is left") and _no(T, "7 left")),
    ("bisect: commits=6 first_bad=4 counts=off", "bisect: counts=off shows no count at all",
     lambda T, C: not any(re.search(r"\d+ left|instead of", x) for step in T for x in step) and any("is the first bad commit" in x for x in T[-1])),
    ("graph: A-B-C main; C atag:v1.0#131e7a7; same:B; HEAD=none => + drop:v1.0,same => + B main; gone:C => + B-C main",
     "+ drop: removes an annotated tag and a mark by its word; a commit that was gone: returns when a chain names it again",
     lambda T, C: "v1.0" in T[1] and "=" in T[1] and "v1.0" not in T[2] and "=" not in T[2] and "131e7a7" not in T[2] and "C" not in T[3] and "C" in T[4]),
    ("remotes: [you] A-B-C main; HEAD=none || [origin] A-B main; HEAD=none => [you] + B main; ghost:C || => [you] + C main ||",
     "in panels a ghost commit is solid again when a later '+' state puts a branch on it",
     lambda T, C: any(c.endswith("/7 7") for c in C[2]) and not any(c.endswith("/7 7") for c in C[3])),
    ("stores: boxes=~/work/router:main_worktree|~/work/router-hotfix:linked_worktree|~/work/router-review:linked_worktree|*.git:one_repository rows=1:A:src/router/classify.py|2:B:.git_(a_file:_gitdir:_...)|2:D:worktrees/router-hotfix/HEAD|3:C:git_add;_git_commit arrows=2:B1>D1:gitdir_points_here|3:C1>D1:clean_filter mono=on say_1=One_repository;_three_working_trees",
     "stores: four boxes with paths (rows wrap), a semicolon in a row and in a caption, say_<step>=, arrow labels that wrap",
     lambda T, C: "One repository; three working trees" in T[1] and any(x.endswith("add; git") or "git add;" in x for x in T[3]) and "src/router/" in T[1]),
    ("gates: packet=git_push_origin_main gates=pre-commit_hook:pass:client:can_stop_the_commit|commit-msg:pass:client:can_reject_the_message|pre-push:pass:client:can_stop_the_push|pre-receive:pass:server:can_refuse_every_ref|update:pass:server:one_ref_at_a_time|required_status_checks:stop:server:the_ruleset_says_no|post-receive:skip:server:cannot_stop_anything zones=your_machine,the_server split=3",
     "gates: seven gates keep their names and notes in full (they wrap)", lambda T, C: "checks" in T[0] and _no(T, "…")),
    ("walk: columns=,what_it_reads,what_it_writes rows=git_fetch_origin_main:the_remote's_refs_and_the_objects_you_lack:refs/remotes/origin/main_and_FETCH__HEAD|git_merge_origin/main:two_tips_and_their_merge_base:a_merge_commit,_the_index_and_the_working_tree",
     "walk: an empty first column head keeps its column; cells too wide for the frame wrap instead of being cut",
     lambda T, C: "what it reads" in T[0] and "git fetch origin main" in T[1] and _no(T, "…")),
    ("todo: todo=pick:1edd58e:Add_parser|pick:614c93b:Fix_typo edit=pick:1edd58e:Add_parser|fixup:-C_614c93b:Fix_typo",
     "todo: fixup -C is a verb with an option, in either field", lambda T, C: "fixup -C" in T[1] and "614c93b" in T[1] and "drop" not in T[1]),
    ("push: src=main dst=main local=810dc2f remote=4e1f5fe steps=refspec,result", "push: gatekeepers whose steps are not played are not drawn",
     lambda T, C: _no(T, "your Git") and _no(T, "the server:")),
    ("decide: nodes=q1:Was_it_committed?|a:git_reflog|d:not_in_Git edges=q1>a:yes,_at_least_once_here|q1>d:no,_never_committed_at_all",
     "decide: an edge label of more than 22 characters wraps", lambda T, C: _no(T, "…")),
]


def main():
    t0 = time.time()
    shutil.rmtree(TEST, ignore_errors=True)
    (TEST / "scripts").mkdir(parents=True)
    ff, fp = find_tool("ffmpeg"), find_tool("ffprobe")

    print("  a. commit-graph parser")
    g1, g2, g3 = AP.parse_graph(G1), AP.parse_graph(G2), AP.parse_graph(G3)
    par = {c["id"]: c["parents"] for c in (g1 or {}).get("commits", [])}
    check("a branching graph: 4 commits, the fork, both labels, HEAD and the note under the caret",
          bool(g1) and par.get("5aec6e0") == ["6ae3c51"] and par.get("c089834") == ["6ae3c51"] and g1["states"][0]["refs"] == {"feature/rationale": "58a5e60", "main": "c089834"}
          and g1["states"][0]["head"] == "main" and g1["states"][0]["notes"][0]["at"] == "6ae3c51")
    check("Before / After panels become two states in which the label has moved",
          bool(g2) and len(g2["states"]) == 2 and g2["states"][0]["refs"]["main"] == "6ae3c51" and g2["states"][1]["refs"]["main"] == "23db174"
          and g2["states"][1]["caption"].startswith("After"))
    par3 = {c["id"]: sorted(c["parents"]) for c in (g3 or {}).get("commits", [])}
    check("a merge commit gets both parents", bool(g3) and par3.get("ae6795c") == ["191bbd1", "59c914e"], str(par3.get("ae6795c")))
    check("drawings that are not commit graphs are refused (they keep their still slide)", all(AP.parse_graph(t) is None for t in NOT_GRAPHS))

    print("  b. tags")
    tags = {"graph: A-B-C main; B-D feature": "graph", "merge: fast-forward versus three-way": "merge", "rebase: feature onto main": "rebase",
            "trees: file=app.py": "trees", "objects: shared blobs": "objects", "remotes: with Asha": "remotes", "reflog: on main": "reflog",
            "pr: feature into main": "pr", "ci: push (checkout, test)": "ci", "sandbox:": "sandbox", "hash: differs=byte": "hash"}
    got = {t: (AP.parse_tag(t) or {}).get("scene") for t in tags}
    check("every scene of the vocabulary parses", got == tags, ", ".join(sorted(set(tags.values()))))
    check("'step: copy' advances a scene; nonsense is refused", AP.parse_tag("step: copy") == {"step": "copy"} and AP.parse_tag("juggle: three balls") is None)
    more = {"flow: actors=a,b msgs=1>2:x": "flow", "gates: gates=a:pass|b:stop": "gates", "layers: layers=a:x+y|b:z": "layers", "walk: columns=a,b rows=1:2|3:4": "walk",
            "match: rules=*:a|/x/:b paths=x/y:1+2": "match", "decide: nodes=q:Q?|a:A|b:B edges=q>a:yes|q>b:no": "decide", "stores: boxes=a|b rows=1:A:x|1:B:y": "stores",
            "bars: bars=a:1|b:2": "bars", "blame: lines=abc1234:x|def5678:y": "blame", "todo: todo=pick:abc1234:x|pick:def5678:y": "todo", "push: src=main dst=main": "push",
            "ladder:": "ladder", "run: jobs=a|b:a": "run", "bisect: commits=8 first_bad=5": "graph", "stash: on main": "graph", "tags: commits=A,B": "graph",
            "codeowners: rules=*:a paths=x:1": "match", "hooks: gates=a:pass": "gates", "ruleset: layers=a:x": "layers", "lifecycle: nodes=a:A|b:B edges=a>b:go": "decide",
            "remotes: [you] A-B main || [origin] A-B-C main": "graph", "objects: cards=commit:a1f3c9e:tree_4b82d10,tree:4b82d10:x": "objects"}
    got = {t: (AP.parse_tag(t) or {}).get("scene") for t in more}
    check("the new scenes, the presets and the topic names parse", got == more, ", ".join(t.split(":")[0] for t in more if got[t] != more[t]) or f"{len(more)} tags")
    g = (AP.parse_tag("graph: A-B-...9-C main; HEAD=none; good:A; bad:C; range:B,C:A..C; note:B:base => + test:B; cmd:git_bisect_good; name:half") or {}).get("params", {})
    check("the graph notation: marks, a range, a note, an elision, no HEAD, a named step with its own command line",
          [c.get("kind") for c in g.get("commits", [])] == [None, None, "elision", None] and g["states"][1]["marks"] == {"A": "good", "C": "bad"} and g["states"][1]["head"] is None
          and g["states"][2]["name"] == "half" and g["states"][2]["cmd"] == "git bisect good" and g["states"][2]["marks"]["B"] == "test" and AP.scene_steps("graph", g) == ["grow", "state-1", "half"])
    check("the tags for a held scene: say, twig, replay, and a step that names its scene",
          AP.parse_tag("say: A new caption") == {"say": "A new caption"} and AP.parse_tag("twig: nod") == {"twig": "nod"} and AP.parse_tag("twig: dance") is None
          and AP.parse_tag("replay: hash") == {"replay": "hash"} and AP.parse_tag("step: rebase.copy") == {"step": "rebase.copy"})
    ref_doc = (HERE.parent / "video" / "production" / "ANIMATION_STYLE.md").read_text(encoding="utf-8")
    examples = [m.group(1).strip() for m in TAG_LINE.finditer(ref_doc) if not m.group(1).startswith("scene:")]
    not_ok = [e[:60] for e in examples if AP.parse_tag(e) is None]
    check("every example tag in ANIMATION_STYLE.md is understood by the planner", len(examples) >= 30 and not not_ok, f"{len(examples)} examples" if not not_ok else "; ".join(not_ok[:3]))
    (TEST / "scripts" / "V998-held-scenes.md").write_text(SCRIPT2, encoding="utf-8")
    sb8 = video_storyboard.build("V998")
    sc8 = [s for s in sb8["slides"] if s["kind"] == "scene"]
    b8 = sb8["beats"]
    check("say: gives a held scene a new caption without advancing it", any(s.get("says") == ["Both names are on B"] and s["upto"] == 2 for s in sc8) and not sb8["warnings"], str(sb8["warnings"])[:200])
    check("twig: sets the mascot's pose for the next paragraph only", [b["anim"]["pose"] for b in b8 if b.get("twig")] == ["nod"] and sum(1 for b in b8 if b["anim"]["pose"] == "nod") == 1)
    check("step: with a scene id brings that scene back; replay: starts a scene again from its first step",
          any(s["scene"] == "graph" and s.get("base") == 2 and s["upto"] == 3 for s in sc8) and sum(1 for s in sc8 if s["scene"] == "hash" and s["upto"] == 1) >= 1
          and [b["slide"] for b in b8 if b["type"] == "narration" and b["text"].startswith("Once more")] == [next(s["n"] for s in sc8 if s["scene"] == "hash" and s["upto"] == 1)])
    cues8 = [c for b in b8 for c in b["anim"]["cues"]]
    check("point_<step> and twig_<step> give the cue of that step its pose", any(c.get("pose") == "pointing" for c in cues8) and any(c.get("says") for c in cues8))
    fixes_planner()
    (TEST / "scripts" / "V000-animation-self-test.md").write_text(SCRIPT, encoding="utf-8")
    sb = video_storyboard.build("V000")
    STORYBOARDS.mkdir(parents=True, exist_ok=True)
    (STORYBOARDS / "V000.json").write_text(json.dumps(sb, ensure_ascii=False, indent=1), encoding="utf-8")
    kinds = [s["kind"] for s in sb["slides"]]
    scene_slides = [s for s in sb["slides"] if s["kind"] == "scene"]
    check("the tagged script gets scene slides whose steps follow the paragraphs", [s["upto"] for s in scene_slides] == [2, 5] or [s["upto"] for s in scene_slides] == [3, 5],
          f"steps shown per beat: {[s['upto'] for s in scene_slides]}")
    check("the tag that is not understood is reported, not fatal", any("not understood" in w for w in sb["warnings"]))
    dia = [s for s in sb["slides"] if s["kind"] == "diagram"]
    check("the ASCII graph in the script was attached to its slide as a scene", len(dia) == 1 and "graph" in dia[0] and len(dia[0]["graph"]["states"]) == 2)
    check("every beat has an animation plan", all("anim" in b and "cues" in b["anim"] for b in sb["beats"]))
    term = next(b for b in sb["beats"] if any(c["fx"] == "terminal" for c in b["anim"]["cues"]))
    ats = [c["at"] for c in term["anim"]["cues"]]
    check("the second command is typed when the narration names it, not at the start", len(ats) == 2 and ats[0] == 0 and 0.3 < ats[1] < 0.8, f"cues at {ats}")
    plain = SCRIPT.split("## DIAGRAM")[0].replace("**[ANIMATION]** rebase: topic onto main\n\n", "").replace("**[ANIMATION]** this tag is not a scene\n\n", "")
    (TEST / "scripts" / "V999-no-tags.md").write_text(plain.replace("V000", "V999"), encoding="utf-8")
    sb9 = video_storyboard.build("V999")
    check("a script without tags gets no scene slides and no warnings", not any(s["kind"] == "scene" for s in sb9["slides"]) and not sb9["warnings"],
          f"kinds: {sorted(set(s['kind'] for s in sb9['slides']))}")

    print("  c. scene library")
    # The sample tags: every scene tag of the demo script (tools/anim/demo), which shows each scene and each generalization once, plus the
    # plain form of every v1 scene.  For each: the planner's step names against the JavaScript's, a full run, and a layout check of every state.
    demo_text = next((ANIM_JS / "demo").glob("V000-*.md")).read_text(encoding="utf-8")
    sample_tags = list(tags) + [m.group(1).strip() for m in TAG_LINE.finditer(demo_text)] + [t for t, _, _ in FIX_TAGS]
    samples, seen_tags = [], set()
    for t in sample_tags:
        tag = AP.parse_tag(t)
        if not tag or "scene" not in tag or t in seen_tags: continue
        seen_tags.add(t); samples.append((t, tag))
    lib = TEST / "lib.html"
    lib.write_text('<!doctype html><html><body><div id="scene"></div><script>' + anim_lib() + "</script><script>"
                   "var S=" + json.dumps([[tg["scene"], tg["params"]] for _, tg in samples], ensure_ascii=False) + ";"
                   "var o=S.map(function(x){return Scenes.defs[x[0]]?Scenes.defs[x[0]].steps(x[1]):null;});"
                   "window.__anim={duration:0,sfx:[],info:{steps:o,scenes:Object.keys(Scenes.defs),poses:Object.keys(Mascot.POSES)},seek:function(){}};</script></body></html>", encoding="utf-8")
    jobs = [{"id": "lib", "html": str(lib), "dir": str(TEST / "frames" / "lib")}]
    nstates = 0
    for i, (t, tag) in enumerate(samples):
        doc, steps = look_page(sb, tag)
        hp = TEST / (f"scene-{tag['scene']}.html" if t == "rebase: feature onto main" else f"sample-{i:02d}.html")
        hp.write_text(doc, encoding="utf-8")
        jobs.append({"id": f"run{i}", "html": str(hp), "dir": str(TEST / "frames" / f"run{i}"), "max_frames": 2})
        free = AP.SCENES[tag["scene"]].get("free")
        for k in range(1, len(steps) + 1):
            lp = TEST / f"sample-{i:02d}-lint{k}.html"
            lp.write_text(look_page(sb, tag, {"min": LINT_MIN if free else LINT_MIN_V1}, k)[0], encoding="utf-8")
            jobs.append({"id": f"lint{i}.{k}", "html": str(lp), "dir": str(TEST / "frames" / f"lint{i}.{k}"), "max_frames": 1})
            nstates += 1
    res = video_animate.shoot(jobs, 6, tag="test")
    info = (res.get("lib") or {}).get("info", {})
    js = info.get("steps", [])
    want = [AP.scene_steps(tg["scene"], tg["params"]) + AP.extra_steps(tg["scene"], tg["params"]) for _, tg in samples]
    wrong = [samples[i][0][:60] for i in range(len(samples)) if i >= len(js) or js[i] != want[i]]
    check("JavaScript and Python agree on scenes and step names", not wrong and sorted(info.get("scenes", [])) == sorted(AP.SCENES),
          f"{len(samples)} sample tags, {len(AP.SCENES)} scenes" if not wrong else "; ".join(wrong[:4]))
    check("the mascot has the poses the storyboard uses", sorted(info.get("poses", [])) == sorted(video_animate.POSES), ", ".join(info.get("poses", [])))
    used = {tg["scene"] for _, tg in samples}
    check("every scene of the library is shown by a sample tag (the demo script covers the whole library)", used == set(AP.SCENES), "missing: " + ", ".join(sorted(set(AP.SCENES) - used)) if used != set(AP.SCENES) else f"{len(used)} scenes")
    bad = [samples[i][0][:50] + ": " + str((res.get(f"run{i}") or {}).get("errors"))[:160] for i in range(len(samples)) if not (res.get(f"run{i}") or {}).get("ok")]
    check(f"all {len(AP.SCENES)} scenes run from first step to last without a JavaScript error, in every sample", not bad, "failed: " + " | ".join(bad[:3]) if bad else f"{len(samples)} runs")
    findings = []
    for i, (t, tag) in enumerate(samples):
        for k in range(1, 40):
            r = res.get(f"lint{i}.{k}")
            if r is None: break
            if not r.get("ok"): findings.append(f"{t[:40]} step {k}: {str(r.get('errors'))[:120]}")
            for f in (r.get("info") or {}).get("lint") or []: findings.append(f"{t[:40]} step {k}: {f}")
    check("layout check of every state of every sample: no text cut off at the edge, none on top of other text, none too small", not findings,
          f"{nstates} states" if not findings else f"{len(findings)} findings; " + " | ".join(findings[:4]))
    if findings and "-v" in sys.argv:
        for f in findings: print("      ", f)
    for t, what, test in FIX_TAGS:                           # the reported defects, as they are drawn
        i = next((k for k, (x, _) in enumerate(samples) if x == t), None)
        infos = [] if i is None else [(res.get(f"lint{i}.{k}") or {}).get("info") or {} for k in range(1, len(look_page(sb, samples[i][1])[1]) + 1)]
        try: ok = bool(infos) and bool(test([x.get("texts") or [] for x in infos], [x.get("circles") or [] for x in infos]))
        except Exception as e: ok = False; what += f" ({type(e).__name__}: {e})"
        check(what, ok, "" if ok else t[:70])

    print("  d. repeatable frames")
    hp = TEST / "scene-rebase.html"
    two = video_animate.shoot([{"id": k, "html": str(hp), "dir": str(TEST / "frames" / k), "max_frames": 40} for k in ("r1", "r2")], 2, tag="test")
    same = all((TEST / "frames" / "r1" / f"{i:05d}.jpg").read_bytes() == (TEST / "frames" / "r2" / f"{i:05d}.jpg").read_bytes() for i in range(40)) \
        if all((two.get(k) or {}).get("frames") == 40 for k in ("r1", "r2")) else False
    distinct = len({hashlib.sha1((TEST / "frames" / "r1" / f"{i:05d}.jpg").read_bytes()).hexdigest() for i in range(40)}) if same else 0
    check("two renders of the same page give byte-identical frames", same, f"40 frames compared, {distinct} distinct pictures")
    check("and the frames really move (time is driven, not frozen)", distinct >= 25)

    if not ff or not fp:
        print("  SKIP  ffmpeg is not installed: clips and the finished video could not be tested")
        return finish(t0)

    print("  e. clips")
    subprocess.run([sys.executable, str(HERE / "video_slides.py"), "V000"], capture_output=True)
    man, n, problems = video_animate.animate("V000", force=True, nproc=5, quiet=True)
    check("every clip of the test video rendered", not problems and man["complete"], f"{len(man['clips'])} clips" + (f"; {problems[:2]}" if problems else ""))
    wrong = []
    total = 0
    for cid, c in man["clips"].items():
        nf, w, h, rate = video_animate.clip_frames(fp, ANIM / "V000" / "clips" / f"{cid}.mp4")
        total += nf
        if (nf, w, h, rate) != (c["frames"], 1920, 1080, "30/1"): wrong.append((cid, nf, c["frames"], w, h, rate))
    check("no missing frames: each clip file holds exactly the frames its page announced, at 1920x1080 and 30 fps", not wrong, f"{total} frames in {len(man['clips'])} clips" if not wrong else str(wrong[:3]))
    check("clips last only as long as something moves", max(c["frames"] for c in man["clips"].values()) <= 360 and total / len(man["clips"]) < 120,
          f"longest {max(c['frames'] for c in man['clips'].values()) / 30:.1f} s, average {total / len(man['clips']) / 30:.1f} s")
    check("reveals carry their soft sounds", any(c["sfx"] for c in man["clips"].values()), f"{sum(len(c['sfx']) for c in man['clips'].values())} sound cues")

    print("  f. timeline")
    durs = [b["est"] for b in sb["beats"]]
    segs, tot, sounds = video_build.anim_timeline(sb, man, durs)
    cover = sorted((s["f"], s["f"] + s["n"]) for s in segs)
    gapless = cover[0][0] == 0 and cover[-1][1] == tot and all(a[1] == b[0] for a, b in zip(cover, cover[1:]))
    check("every frame belongs to exactly one segment", gapless, f"{len(segs)} segments, {tot} frames")
    check("a clip is never cut off: it is squeezed when its slot is shorter", all(s["used"] <= s["n"] for s in segs))

    print("  g. finished video")
    voice = "Samantha"
    try: video_build.pick_voice(voice)
    except SystemExit: voice = video_build.pick_voice()
    r = subprocess.run([sys.executable, str(HERE / "video_build.py"), "--draft", "--voice", voice, "--rate", "200", "--force", "V000"], capture_output=True, text=True)
    rep_path = OUT / "V000.build.json"
    if r.returncode != 0 or not rep_path.exists():
        check("the animated test video was built", False, (r.stdout + r.stderr)[-400:])
        return finish(t0)
    rep = json.loads(rep_path.read_text())
    p = rep["probe"]
    check("the builder used the animation layer", rep.get("animated") is True, f"{rep['animation']['segments']} segments, {rep['animation']['clip_frames']} animated frames of {p['frames']}")
    check("MP4 is 1920x1080, 30 fps, H.264 + AAC", (p["width"], p["height"], p["fps"], p["vcodec"], p["acodec"]) == (1920, 1080, "30/1", "h264", "aac"))
    check("the frame count is exact", p["frames"] == rep["animation"]["frames"] == round(rep["seconds"] * 30), f"{p['frames']} frames")
    check("audio and video lengths agree within 0.1 s", abs(p["video_seconds"] - p["audio_seconds"]) <= 0.1, f"video {p['video_seconds']:.3f} s, audio {p['audio_seconds']:.3f} s")
    check("the video is as long as its narration (within 0.1 s)", abs(p["video_seconds"] - rep["seconds"]) <= 0.1, f"{rep['seconds']:.2f} s planned")
    check("sound effects were mixed in", rep["animation"]["sound_effects"] > 0, f"{rep['animation']['sound_effects']}")
    r2 = subprocess.run([sys.executable, str(HERE / "video_build.py"), "--draft", "--voice", voice, "--rate", "200", "--force", "--no-anim", "V000"], capture_output=True, text=True)
    rep2 = json.loads(rep_path.read_text()) if r2.returncode == 0 else {}
    check("--no-anim still builds the same video from still slides, with the same length", rep2.get("animated") is False and abs(rep2["probe"]["video_seconds"] - p["video_seconds"]) <= 0.1,
          f"{rep2.get('probe', {}).get('video_seconds', 0):.2f} s")

    print("  h. pronunciation")
    sp = video_build.speakable
    cases = {"Look in .git and .gitignore.": "Look in dot git and dot git ignore.",
             "Use --force-with-lease.": "Use dash dash force with lease.",
             "Go to HEAD~2.": "Go to HEAD tilde two.",
             "Compare main..topic and main...topic.": "Compare main two dots topic and main three dots topic.",
             "Run labs/shell on origin/main and refs/heads/main.": "Run labs slash shell on origin main and refs heads main.",
             "Open README.md, a YAML file, a SHA.": "Open read me dot M D, a yammel file, a shah."}
    wrong = {k: sp(k) for k, v in cases.items() if sp(k) != v}
    check("the pronunciation table: dot git, dash dash, tilde, two dots, slash, read me, yammel, shah", not wrong, str(wrong)[:300] if wrong else f"{len(cases)} sentences")
    check("an object ID is read as 'commit' and four characters", sp("The base is 6ae3c51.") == "The base is commit 6 a e 3.", sp("The base is 6ae3c51."))
    check("'Root cause:' is set off by pauses", video_build.PAUSE in sp('It failed. Root cause: the tip moved.'))
    # how symbols are spoken (video/NARRATION_STYLE.md): text only, also run alone by  python3 tools/video_build.py --speech-selftest
    bad = video_build.speech_selftest()
    check("symbols are spoken as words, prose is untouched, and the voice cache key follows the spoken text", not bad,
          " | ".join(bad)[:400] if bad else f"{len(video_build.SPEECH_CASES)} sentences")
    srt = (OUT / "V000.srt").read_text(encoding="utf-8") if (OUT / "V000.srt").exists() else ""
    check("subtitles keep the script's spelling (only the voice is changed)", "git status --short" in srt and "dash dash" not in srt)

    print("  i. backward compatibility of the planner (frozen v1 reference in tools/anim/compat)")
    compat_planner()
    return finish(t0)


def fixes_planner():
    """The defects reported by the script editors of V034 to V088, as far as the planner decides them."""
    P = lambda t: (AP.parse_tag(t) or {}).get("params") or {}
    (TEST / "scripts" / "V997-library-fixes.md").write_text(SCRIPT3, encoding="utf-8")
    try: sb = video_storyboard.build("V997")
    except Exception as e: sb = None; check("at_<step>= on a graph tag: the storyboard is built", False, f"{type(e).__name__}: {e}")
    if sb:
        sl = {s["n"]: s for s in sb["slides"]}
        beat = lambda start: next((b for b in sb["beats"] if b["type"] == "narration" and b["text"].startswith(start)), None)
        cue = [c for c in (beat("Some words") or {"anim": {"cues": []}})["anim"]["cues"] if c.get("to") == 3]
        check("at_<step>= on a graph tag: the storyboard is built and the step starts at 40 %", bool(cue) and cue[0]["at"] == 0.4, str(cue)[:120])
        b1, b2 = beat("The drawing is shown"), beat("The caption changes")
        check("'end' directly before [DIAGRAM] keeps the drawing", bool(b1) and sl[b1["slide"]]["kind"] == "diagram", sl[b1["slide"]]["kind"] if b1 else "no beat")
        check("'say:' that brings a scene back changes the caption and plays no step; its text follows the underscore rule",
              bool(b2) and sl[b2["slide"]].get("upto") == 2 and sl[b2["slide"]].get("says") == ["Still two commits, and no ORIG_HEAD"], str({k: sl[b2["slide"]].get(k) for k in ("upto", "says")}) if b2 else "")
        check("'replay:' directly before [DIAGRAM] is reported", sum("replay" in w and "silence" in w for w in sb["warnings"]) == 1 and len(sb["warnings"]) == 1, str(sb["warnings"])[:160])
        check("a scene tag right after on-screen text is reported (as a hint: the plan is unchanged)", len(sb.get("hints", [])) == 1 and "held in silence" in sb["hints"][0], str(sb.get("hints"))[:160])
        fl = beat("Version 2 of the helper")
        check("steps called 1, 2 ... are not placed at digits in the narration", bool(fl) and [c["at"] for c in fl["anim"]["cues"]] == [0.0, 0.41, 0.82], str([c["at"] for c in fl["anim"]["cues"]]) if fl else "")
    check("at_<step>= is read as a fraction in a graph, a preset and objects with cards=; a wrong step or value is refused",
          P("graph: A-B main => A-B-C main at_state_2=40").get("at") == {"state-2": 0.4} and P("bisect: commits=8 at_found=30 say_found=Here").get("at") == {"found": 0.3}
          and P("bisect: commits=8 say_found=Here").get("say") == {"found": "Here"} and P("objects: cards=commit:a1f3c9e:tree_4b82d10,tree:4b82d10:x at_level_2=30").get("at") == {"level-2": 0.3}
          and AP.parse_tag("graph: A-B main at_state_1=x") is None and AP.parse_tag("bisect: commits=8 say_nope=x") is None)
    g = P("graph: A-...-B-C main; ...-D side; HEAD=none")
    check("a bare ... followed by -id is an unnamed elision", [(c["id"], c.get("text"), c["parents"]) for c in g.get("commits", [])][1:3] == [("...", "", ["A"]), ("B", None, ["..."])]
          and [c["parents"] for c in g["commits"] if c["id"] == "D"] == [["..."]] and P("graph: A-B-...14-C main")["commits"][2]["text"] == "14 more")
    b = P("blame: lines=a1:__NAME_=_1|a1:____x_=___NAME|a1:______y|a1:\u200b__Z indent=4 from=41")
    b0 = P("blame: lines=a1:__key:_v|a1:____x")
    check("blame: indent= lets a line start with an underscore, from= sets the first number, and without them nothing changes",
          [l[1] for l in b.get("lines", [])] == ["_NAME = 1", "    x = _NAME", "    _y", "\u200b_Z"] and b.get("from") == 41 and [l[1] for l in b0.get("lines", [])] == ["  key: v", "    x"]
          and "from" not in b0 and AP.parse_tag("blame: lines=a:b from=0") is None)
    bs = P("bisect: commits=8 tests=D:good|F:skip|G:bad counts=20,10,10,5 skip=E")
    st = {s.get("name"): s for s in bs.get("states", [])}
    check("bisect: counts=, counts=off, a skip in tests= and skip=",
          bool(st) and st["start"]["sets"]["range"]["label"] == "20 left" and st["start"]["marks"].get("E") == "skip" and st["mark-2"]["marks"].get("F") == "skip" and st["mark-2"]["cmd"] == "git bisect skip"
          and st["mark-3"]["caption"] == "G is bad: 5 left" and "middle" not in st["test-1"]["caption"]
          and all("label" not in (s["sets"].get("range") or {}) and not re.search(r"\d left|instead of", s.get("caption") or "") for s in P("bisect: commits=8 counts=off")["states"])
          and AP.parse_tag("bisect: commits=8 counts=many") is None)
    g = P("graph: A-B-C main; C atag:v1.0#131e7a7; same:B; mark:picked_here:A; HEAD=none => + drop:v1.0,same,picked_here => + B main; gone:C => + B-C main")
    check("+ drop: removes an annotated tag and a mark by its word; a commit that was gone: comes back",
          bool(g) and g["states"][2]["refs"] == {"main": "C"} and g["states"][2]["marks"] == {} and g["states"][3].get("gone") == ["C"] and g["states"][4].get("back") == ["C"])
    g = P("graph: [a] A-B-C main; HEAD=none || [b] A main; HEAD=none => [a] + B main; C ORIG_HEAD; reflog:C || => [a] + C HEAD@{1} || => [a] + C rescue ||")
    check("a branch put on a commit by a '+' state ends its ghost: or reflog: state; a name such as HEAD@{1} does not",
          bool(g) and [s["p"][0].get("reflog") for s in g["states"]] == [[], [], ["C"], ["C"], []])
    g = P("graph: A-B main => + A-B-C main; cmd:git_commit => + cmd:off; say:off")
    check("cmd:off and say:off in a graph state", bool(g) and g["states"][3].get("cmd") == "" and g["states"][3].get("caption") == "off")
    check("a ?placeholder may be a long word: nothing is split off", [c.get("text") for c in P("graph: A-?the_Wednesday_copy-?Monday main").get("commits", [])] == [None, "the Wednesday copy", "Monday"])
    check("three panels with eight commits in a row are stacked, unless layout= says otherwise",
          P("graph: [a] A-B-C-D-E-F-G-H main || [b] A main || [c] A main").get("layout") == "rows" and P("graph: [a] A-B-C-D-E-F-G-H main || [b] A main || [c] A main layout=columns").get("layout") == "columns"
          and "layout" not in P("graph: [a] A-B-C main || [b] A main || [c] A main"))
    s3 = P("stores: boxes=a:x|b:y rows=1:A:git_add;_git_commit|1:B:y; mono=on")
    check("a semicolon inside a value belongs to it (outside the graph notation)", s3.get("rows") == [[1, "A", "git add; git commit"], [1, "B", "y"]] and s3.get("mono") == "on")
    check("trees: forms_<step>=", P("trees: forms=CRLF,LF,LF forms_add=LF,LF,LF").get("forms_steps") == {"add": ["LF", "LF", "LF"]} and AP.parse_tag("trees: forms_nope=a,b,c") is None)
    check("walk: an empty column head keeps its column", P("walk: columns=,base,ours rows=a.txt:v1:v2").get("columns") == ["", "base", "ours"] and P("walk: columns=,base,ours rows=a.txt:v1:v2").get("rows") == [["a.txt", "v1", "v2"]])
    check("todo: -C in the ID field belongs to the verb", P("todo: todo=pick:614c93b:Fix edit=fixup:-C_614c93b:Fix").get("edit") == [["fixup -C", "614c93b", "Fix"]])


# ---- backward compatibility ------------------------------------------------------------------------------
# The library was frozen as "v1" when batch one (V001 to V033) was approved.  tools/anim/compat/ holds the JavaScript of
# that moment and what the planner made of every tag, drawing and script then.  Everything below compares "then" with "now".
COMPAT = HERE / "anim" / "compat"
SNAP = COMPAT / "planner-v1.json.gz"
V1_JS = ("engine.js", "scenes.js", "mascot.js")
BATCH_ONE = [f"V{n:03d}" for n in range(1, 34)]
BUILT = ["V000"] + BATCH_ONE                            # the demo video and batch one: their clips are compared frame by frame
TAG_LINE = re.compile(r"^\*\*\[ANIMATION\]\*\*[ \t]*(.*)$", re.M)
FENCE = re.compile(r"^```(?:text)?\n(.*?)^```", re.M | re.S)


def _canon(x):
    return json.loads(json.dumps(x, ensure_ascii=False, sort_keys=True))


def compat_board(vid):
    """What the planner makes of one script: its scene slides and the animation plan of every beat.  V000 is the demo script."""
    keep = os.environ.get("VIDEO_SCRIPTS_DIR")
    if vid == "V000": os.environ["VIDEO_SCRIPTS_DIR"] = str(ANIM_JS / "demo")
    try: sb = video_storyboard.build(vid)
    finally:
        if keep is None: os.environ.pop("VIDEO_SCRIPTS_DIR", None)
        else: os.environ["VIDEO_SCRIPTS_DIR"] = keep
    scenes = [{k: v for k, v in s.items() if not k.startswith("_")} for s in sb["slides"] if s["kind"] == "scene" or (s["kind"] == "diagram" and s.get("graph"))]
    plan = [[b["i"], b["slide"], b["anim"]] for b in sb["beats"]]
    return sb, _canon({"script_sha1": sb.get("script_sha1"), "warnings": sb["warnings"], "scenes": scenes, "plan": plan})


def compat_now(ids=None):
    files = sorted(SCRIPTS.glob("V[0-9][0-9][0-9]-*.md")) + sorted((ANIM_JS / "demo").glob("*.md"))
    tags, graphs = {}, {}
    for p in files:
        text = p.read_text(encoding="utf-8")
        for m in TAG_LINE.finditer(text): tags.setdefault(m.group(1).strip(), None)
        for m in FENCE.finditer(text): graphs.setdefault(m.group(1), None)
    for t in tags: tags[t] = AP.parse_tag(t)
    for g in graphs: graphs[g] = AP.parse_graph(g)
    boards, sbs = {}, {}
    for vid in (ids or ["V000"] + all_script_ids()):
        sbs[vid], boards[vid] = compat_board(vid)
    return _canon({"tags": tags, "graphs": graphs, "boards": boards}), sbs


def compat_snapshot(force):
    if SNAP.exists() and not force:
        print(f"{rel(SNAP)} exists: the reference is frozen. Pass --force to replace it (only when a new baseline is intended)."); return 2
    (COMPAT / "v1").mkdir(parents=True, exist_ok=True)
    for f in V1_JS: shutil.copyfile(ANIM_JS / f, COMPAT / "v1" / f)
    now, _ = compat_now()
    now["frozen"] = time.strftime("%Y-%m-%d")
    with gzip.open(SNAP, "wt", encoding="utf-8") as f: json.dump(now, f, ensure_ascii=False, sort_keys=True)
    print(f"frozen: {len(now['tags'])} tags, {len(now['graphs'])} drawings, {len(now['boards'])} storyboard plans, the JavaScript of {', '.join(V1_JS)} -> {rel(COMPAT)}")
    return 0


def compat_planner(verbose=False):
    """-> (the frozen reference, the storyboards as they are now, problems found)"""
    if not SNAP.exists():
        check("a frozen v1 reference exists (tools/anim/compat)", False); return {}, {}, 1
    with gzip.open(SNAP, "rt", encoding="utf-8") as f: old = json.load(f)
    now, sbs = compat_now(sorted(old["boards"]))
    bad_t = [t for t in old["tags"] if t not in now["tags"] and _canon(AP.parse_tag(t)) != old["tags"][t] or t in now["tags"] and now["tags"][t] != old["tags"][t]]
    check(f"all {len(old['tags'])} [ANIMATION] tags of the frozen scripts parse to exactly the same scene, parameters and steps", not bad_t,
          "; ".join(repr(t[:70]) for t in bad_t[:4]))
    bad_g = [g for g in old["graphs"] if _canon(AP.parse_graph(g)) != old["graphs"][g]]
    check(f"all {len(old['graphs'])} drawings in text fences are read as before ({sum(1 for v in old['graphs'].values() if v)} of them commit graphs)", not bad_g,
          "; ".join(repr(g.strip()[:50]) for g in bad_g[:3]))
    same, changed, bad_b = [], [], []
    for vid, o in old["boards"].items():
        n = now["boards"].get(vid)
        if n is None or n["script_sha1"] != o["script_sha1"]: changed.append(vid)
        elif n != o: bad_b.append(vid)
        else: same.append(vid)
    check(f"the scene slides and the animation plan of every unchanged script are identical ({len(same) + len(bad_b)} scripts; {len(changed)} edited since the freeze are not compared)",
          not bad_b, ", ".join(bad_b[:12]))
    stale_b1 = [v for v in BATCH_ONE if v in changed]
    check("batch one (V001 to V033): no script was edited, so no built video changed its meaning", not stale_b1, ", ".join(stale_b1))
    if verbose:
        for t in bad_t[:10]: print("   tag", repr(t), "\n     was", json.dumps(old["tags"][t], ensure_ascii=False)[:600], "\n     now", json.dumps(_canon(AP.parse_tag(t)), ensure_ascii=False)[:600])
        for vid in bad_b[:6]:
            o, n = old["boards"][vid], now["boards"][vid]
            for k in ("warnings", "scenes", "plan"):
                if o[k] != n[k]:
                    d = next((i for i, (a, b) in enumerate(zip(o[k], n[k])) if a != b), min(len(o[k]), len(n[k])))
                    print(f"   {vid} {k}[{d}]\n     was {json.dumps(o[k][d] if d < len(o[k]) else None, ensure_ascii=False)[:700]}\n     now {json.dumps(n[k][d] if d < len(n[k]) else None, ensure_ascii=False)[:700]}")
    return old, sbs, len(bad_t) + len(bad_g) + len(bad_b)


def compat_items(old, sbs, motion, only=None):
    """The distinct scene pages of the frozen storyboard plans: stills (the picture after each step that is shown) or whole clips.
    The plans are the frozen ones, so a script that was edited since the freeze is still compared as it was."""
    items = {}
    frame_sb = sbs.get("V001") or next(iter(sbs.values()))
    for vid, board in sorted(old["boards"].items()):
        if only and vid not in only: continue
        sb = sbs.get(vid) or next(iter(sbs.values()))          # the frame around the scene: title bar, palette
        slides = {s["n"]: dict(s) for s in board["scenes"]}
        reach = {}
        key = lambda s: json.dumps([s["scene"], s.get("params"), s.get("steps")], sort_keys=True)
        for s in slides.values():
            if s["kind"] == "scene": reach[key(s)] = max(reach.get(key(s), 0), s["upto"])
        for s in slides.values():
            if s["kind"] == "scene": s["_fit_to"] = reach[key(s)]
        state, group = None, None
        for i, sn, a in board["plan"]:
            if a["group"] != group: state = None
            group = a["group"]
            for c in a["cues"]:
                s = slides.get(sn)
                cfg = video_animate.cue_cfg(sb, s, c, None, state) if s else None
                if "to" in c: state = c["to"]
                if not cfg or (cfg.get("base") or cfg["fx"]) != "scene": continue
                if not motion:
                    cfg = dict(cfg, fx="still", base="scene", **{"from": cfg["to"]}); cfg.pop("focus", None)
                elif cfg["fx"] == "still": continue
                k = sha1(json.dumps(cfg, sort_keys=True, ensure_ascii=False))[:16]
                # the same frame around every page (section name, progress bar): only the scene is compared
                if k not in items: items[k] = (vid, frame_sb, dict(s, section="COMPAT", progress=0.5, n=1, caption=s.get("caption") and "caption"), cfg)
    return items


def compat_render(items, motion, share, nproc):
    """Draw every page with the frozen v1 JavaScript and with the current one; the frames must be byte-identical."""
    chrome = subprocess.run([CHROME, "--version"], capture_output=True, text=True).stdout.strip().replace(" ", "_") or "chrome"
    refdir = TEST / "ref" / chrome / ("motion" if motion else "stills")
    refdir.mkdir(parents=True, exist_ok=True)
    keys = sorted(items)
    if share: keys = [k for i, k in enumerate(keys) if i % share[1] == share[0] - 1]
    only = [a for a in sys.argv if re.fullmatch(r"[0-9a-f]{16}(,[0-9a-f]{16})*", a)]      # a list of page keys: only those pages (to look at one difference again)
    if only: keys = [k for k in keys if k in only[0].split(",")]
    v1 = "\n".join((COMPAT / "v1" / f).read_text(encoding="utf-8") for f in V1_JS)
    cur = anim_lib()
    work = TEST / f"work-{os.getpid()}"                    # one directory per run: two runs side by side do not disturb each other
    shutil.rmtree(work, ignore_errors=True); (work / "html").mkdir(parents=True)

    def shoot(lib, tag, ks):
        video_animate.anim_lib = lambda: lib
        jobs = []
        for k in ks:
            vid, sb, s, cfg = items[k]
            hp = work / "html" / f"{tag}-{k}.html"
            hp.write_text(video_animate.page(sb, s, cfg), encoding="utf-8")
            jobs.append({"id": k, "html": str(hp), "dir": str(work / tag / k), "max_frames": 600 if motion else 1})
        res = video_animate.shoot(jobs, nproc, tag="compat")
        out = {}
        for k in ks:
            r = res.get(k) or {}
            d = work / tag / k
            out[k] = {"ok": bool(r.get("ok")), "errors": r.get("errors"), "frames": [sha1((d / f"{i:05d}.jpg").read_bytes()) for i in range(r.get("frames", 0))]}
        return out
    need = [k for k in keys if not (refdir / f"{k}.json").exists()]
    if need:
        for k, r in shoot(v1, "v1", need).items():
            if r["ok"]: (refdir / f"{k}.json").write_text(json.dumps(r["frames"]))
            if not motion and r["ok"]: shutil.copyfile(work / "v1" / k / "00000.jpg", refdir / f"{k}.jpg")
    video_animate.anim_lib = lambda: cur
    now = shoot(cur, "now", keys)
    refs = {k: json.loads((refdir / f"{k}.json").read_text()) if (refdir / f"{k}.json").exists() else None for k in keys}
    # Chrome very rarely draws one frame of a clip with a pixel one grey level off (about one frame in 20,000, also between two renders of the
    # same page).  A page that differs is therefore rendered once more with both libraries: only a difference that shows again counts.
    again = [k for k in keys if refs[k] is None or not now[k]["ok"] or refs[k] != now[k]["frames"]]
    flaky = 0
    if again:
        r1, r2 = shoot(v1, "v1", again), shoot(cur, "now", again)
        for k in again:
            if r1[k]["ok"]: refs[k] = r1[k]["frames"]
            now[k] = r2[k]
            if r1[k]["ok"] and r2[k]["ok"] and r1[k]["frames"] == r2[k]["frames"]: flaky += 1
    bad, frames = [], 0
    diff = TEST / "diff"
    for k in keys:
        ref = refs[k]
        frames += len(now[k]["frames"])
        if ref is None or not now[k]["ok"] or ref != now[k]["frames"]:
            vid, sb, s, cfg = items[k]
            first = next((i for i, (a, b) in enumerate(zip(ref or [], now[k]["frames"])) if a != b), None)
            bad.append((k, vid, cfg["scene"], cfg.get("from"), cfg.get("to"), len(ref or []), len(now[k]["frames"]), first, now[k]["errors"]))
            (diff / k).mkdir(parents=True, exist_ok=True)
            (diff / k / "cfg.json").write_text(json.dumps(cfg, indent=1, ensure_ascii=False))
            i = first if first is not None else 0
            for tag in ("v1", "now"):
                src = work / tag / k / f"{i:05d}.jpg"
                if src.exists(): shutil.copyfile(src, diff / k / f"{tag}.jpg")
                elif tag == "v1" and (refdir / f"{k}.jpg").exists(): shutil.copyfile(refdir / f"{k}.jpg", diff / k / "v1.jpg")
    what = "every frame of every scene clip of batch one and of the demo" if motion else "every scene picture of all 201 frozen storyboards"
    check(f"{what}: the frozen v1 library and the current one draw byte-identical frames", not bad,
          f"{len(keys)} pages, {frames} frames" + (f" of share {share[0]}/{share[1]}" if share else "") + (f"; {flaky} page(s) equal on the second render" if flaky else "")
          + (f"; {len(bad)} DIFFERENT, see {rel(diff)}" if bad else ""))
    for b in bad[:25]: print("     ", b)
    shutil.rmtree(work, ignore_errors=True)
    return len(bad)


def compat_main(argv):
    args = [a for a in argv if a != "--compat"]
    t0 = time.time()
    if "snapshot" in args:
        return compat_snapshot("--force" in args)
    print("  i. backward compatibility against the frozen v1 library")
    old, sbs, bad = compat_planner(verbose=True)
    what = "pictures" if "pictures" in args else "motion" if "motion" in args else None
    if what:
        share = next((tuple(int(x) for x in a.split("/")) for a in args if re.fullmatch(r"\d+/\d+", a)), None)
        nproc = int(args[args.index("--jobs") + 1]) if "--jobs" in args else 6
        compat_render(compat_items(old, sbs, what == "motion", BUILT if what == "motion" else None), what == "motion", share, nproc)
    return finish(t0)


# ---- look at one tag ---------------------------------------------------------------------------------------
LINT_MIN = 24.5          # px on the 1080p frame: the smallest text a schematic scene (scenes2.js, scenes3.js) may show
LINT_MIN_V1 = 15.0       # the scenes of batch one keep their approved sizes (commit IDs of 21 units in a graph that the camera may show at 0.75)


def look_page(sb, tag, lint=None, upto=None, frm=0, part=None):
    """The page of a scene tag played from step frm to step upto (default: all of it)."""
    P = tag["params"]
    steps = AP.scene_steps(tag["scene"], P)
    if tag.get("only"): steps = list(tag["only"])
    elif tag.get("last"): steps = steps[:steps.index(tag["last"]) + 1]
    n = len(steps) if upto is None else upto
    sb = dict(sb)
    if part is not None:
        a, a2, b1, b2, _ = PARTS[part]; sb["palette"] = {"accent": a, "accent2": a2, "bg1": b1, "bg2": b2}
    slide = {"kind": "scene", "scene": tag["scene"], "params": P, "upto": n, "section": "LOOK", "n": 1, "progress": 0.5, "steps": steps}
    cfg = {"fx": "scene", "scene": tag["scene"], "params": P, "steps": steps, "from": frm, "to": n, "palette": sb["palette"], "h": 880, "fit_to": len(steps)}
    if lint: cfg = dict(cfg, fx="still", base="scene", lint=lint, **{"from": n})
    return video_animate.page(sb, slide, cfg), steps


def look_sb():
    (TEST / "scripts").mkdir(parents=True, exist_ok=True)
    (TEST / "scripts" / "V000-look.md").write_text("# V000: Look\n\n- **Part.** 2: Integration\n- **Planned minutes.** 1\n\n## CONCEPT\n\nOne sentence.\n", encoding="utf-8")
    return video_storyboard.build("V000")


def look_main(argv):
    """python3 tools/video_animtest.py --look 'bisect: commits=12 ...' [--name x] [--part 3] [--frames 12] [--full i,j]
    Renders the whole scene, checks every state for small, cut-off or overlapping text, and writes a contact sheet
    (video/production/.cache/look/<name>/sheet.jpg) plus, with --full, some frames at full size."""
    args = [a for a in argv if a != "--look"]
    opt = lambda k, d: (args.pop(args.index(k) + 1), args.remove(k))[0] if k in args else d
    name, part, nfr, full = opt("--name", "scene"), int(opt("--part", "2")), int(opt("--frames", "12")), opt("--full", "")
    text = " ".join(args).strip()
    tag = AP.parse_tag(text)
    if not tag or "scene" not in tag:
        print("the tag is not understood:", text[:120]); return 2
    sb = look_sb()
    out = TEST / name
    shutil.rmtree(out, ignore_errors=True); (out / "frames").mkdir(parents=True)
    doc, steps = look_page(sb, tag, part=part)
    (out / "page.html").write_text(doc, encoding="utf-8")
    jobs = [{"id": "run", "html": str(out / "page.html"), "dir": str(out / "frames"), "max_frames": 1500}]
    for k in range(1, len(steps) + 1):
        hp = out / f"lint{k}.html"; hp.write_text(look_page(sb, tag, {"min": LINT_MIN if AP.SCENES[tag["scene"]].get("free") else LINT_MIN_V1}, k, part=part)[0], encoding="utf-8")
        jobs.append({"id": f"lint{k}", "html": str(hp), "dir": str(out / f"still{k}"), "max_frames": 1})
    res = video_animate.shoot(jobs, 6, tag="look")
    r = res.get("run") or {}
    print(f"{tag['scene']}: steps {', '.join(steps)}; {r.get('frames', 0)} frames ({r.get('duration', 0):.1f} s)" + (f"; ERRORS {r.get('errors')}" if not r.get("ok") else ""))
    clean = True
    for k in range(1, len(steps) + 1):
        rk = res.get(f"lint{k}") or {}
        found = (rk.get("info") or {}).get("lint")
        if not rk.get("ok"): print(f"  after {steps[k - 1]}: ERROR {rk.get('errors')}"); clean = False
        for f in found or []: print(f"  after {steps[k - 1]}: {f}"); clean = False
    if clean: print("  layout check: clean in every state")
    n = r.get("frames", 0)
    if n and find_tool("ffmpeg"):
        pick = sorted({round(i * (n - 1) / (nfr - 1)) for i in range(nfr)}) if n >= nfr else list(range(n))
        sel = out / "sel"; sel.mkdir()
        for j, f in enumerate(pick): shutil.copyfile(out / "frames" / f"{f:05d}.jpg", sel / f"{j:03d}.jpg")
        cols = 4 if len(pick) > 9 else 3
        subprocess.run([find_tool("ffmpeg"), "-y", "-v", "error", "-framerate", "1", "-i", str(sel / "%03d.jpg"), "-vf", f"scale=640:360,tile={cols}x{-(-len(pick) // cols)}:padding=6:color=white",
                        "-frames:v", "1", "-q:v", "3", str(out / "sheet.jpg")], capture_output=True)
        print(f"  contact sheet ({len(pick)} frames: {', '.join(str(f) for f in pick)}): {out / 'sheet.jpg'}")
        for f in [x for x in full.split(",") if x]:
            i = n - 1 if f == "last" else min(n - 1, int(f))
            shutil.copyfile(out / "frames" / f"{i:05d}.jpg", out / f"full-{f}.jpg"); print(f"  full frame {i}: {out / f'full-{f}.jpg'}")
    return 0 if clean and r.get("ok") else 1


def finish(t0):
    bad = results.count(False)
    print(f"  animation layer: {len(results) - bad} checks passed, {bad} failed, in {time.time() - t0:.0f} s")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(compat_main(sys.argv[1:]) if COMPAT_MODE else look_main(sys.argv[1:]) if LOOK_MODE else main())
