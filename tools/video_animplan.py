#!/usr/bin/env python3
"""The animation plan of a storyboard: which beat plays which animation, and when inside the beat.

Used by tools/video_storyboard.py (it calls annotate() on every storyboard it writes) and by tools/video_animate.py.

    python3 tools/video_animplan.py --graph FILE     parse an ASCII commit graph and print the scene parameters
    python3 tools/video_animplan.py --corpus         how many diagram slides of all storyboards parse as commit graphs

Three ways a beat gets motion (see video/production/ANIMATION_STYLE.md):
  1. automatically by slide kind: terminals type, tables and lists reveal, cards and key points rise, drawings draw in;
  2. an ASCII commit graph in a ```text fence is parsed (parse_graph) and replayed by the "graph" scene;
  3. a stage direction  **[ANIMATION]** scene: words  in a script names a library scene (parse_tag).

A beat's plan is  beat["anim"] = {"group": n, "pose": mascot pose, "cues": [{"at": fraction of the beat, "fx": ...,
"from": state, "to": state, "dissolve": bool, ...}]}.  "at" is where in the narration the cue fires (0 = at the start);
the builder turns it into a frame number once the real length of the narration is known.
"""
import json, re, statistics, sys

CODE_RE = re.compile(r"(`+)(.+?)\1")
PLAN_VERSION = 3

# ---- scene library: names and steps (must match tools/anim/scenes.js; the self-test compares them) ----
SCENES = {
    "graph":   {"steps": None, "about": "a commit graph that grows commit by commit; labels slide when they move"},
    "merge":   {"steps": {"ff": ["setup", "check", "fast-forward"], "three-way": ["setup", "merge-base", "merge"],
                          "versus": ["setup", "check", "fast-forward", "merge-base", "merge"]},
                "about": "fast-forward versus three-way merge"},
    "rebase":  {"steps": lambda P: ["setup", "lift", "copy", "conflict", "continue", "ghost", "move"] if P.get("stop") is not None else ["setup", "lift", "copy", "ghost", "move"],
                "about": "commits lifted and copied onto a new base; the originals become ghosts"},
    "trees":   {"steps": ["setup", "edit", "add", "commit", "restore", "reset"], "danger": ["restore", "reset", "restore-source", "reset-hard"],
                "extra": ["edit2", "unstage", "restore-source", "commit-a", "forget", "reset-soft", "reset-mixed", "reset-hard"],
                "about": "working tree, index and HEAD, with a file's content flowing between them"},
    "objects": {"steps": lambda P: [f"level-{i + 1}" for i in range(len(P["levels"]))] if P.get("cards") else ["commit", "tree", "blobs", "second-commit", "shared", "compare"],
                "about": "commit -> tree -> blobs, and two snapshots sharing blobs; with cards=...: any objects (a tag object, nested trees, a gitlink, a missing blob)"},
    "sandbox": {"steps": ["room", "inside", "outside", "enter", "doors", "shield"], "about": "your real setup and the lab sandbox as two separate boxes"},
    "hash":    {"steps": ["one", "same", "different"], "about": "content addressing: same input, same ID; one byte different, another ID"},
    "remotes": {"steps": ["setup", "teammate-push", "fetch", "pull", "commit", "push"], "about": "your clone, origin and a teammate"},
    "reflog":  {"steps": ["setup", "reset", "reflog", "rescue"], "danger": ["reset"], "about": "a branch label yanked back and the lost commits found again"},
    "pr":      {"steps": ["branch", "push", "review", "checks", "merge"], "extra": ["push-again", "dismissed", "re-approve"], "about": "the pull request flow"},
    "ci":      {"steps": ["event", "workflow", "runner", "steps", "result"], "about": "a CI run: event, workflow, job, steps, runner"},
    # ---- schematic scenes (tools/anim/scenes2.js): every label comes from the tag; the steps depend on what the tag lists ----
    "flow":    {"free": True, "steps": lambda P: ["actors"] + _nums(P.get("msgs")), "about": "a sequence between actors: a relay, a handshake, a credential helper, a token exchange"},
    "gates":   {"free": True, "steps": lambda P: ["setup"] + _nums(P.get("gates")) + (["result"] if P.get("result") else []),
                "about": "something travels through checkpoints, each of which can stop it: hooks, rules, a response sequence"},
    "layers":  {"free": True, "steps": lambda P: _nums(P.get("layers")) + (["result"] if P.get("result") or P.get("winner") else []),
                "about": "stacked layers and what they add up to: rulesets, permission levels, precedence"},
    "walk":    {"free": True, "steps": lambda P: ["header"] + _nums(P.get("rows")) + (["pick"] if P.get("pick") else []), "about": "a table read row by row"},
    "match":   {"free": True, "steps": lambda P: ["rules"] + _nums(P.get("paths")), "about": "patterns and the paths they match; last or first match wins"},
    # ---- tools/anim/scenes3.js ----
    "decide":  {"free": True, "steps": lambda P: (["nodes"] + _nums(P.get("edges"))) if P.get("reveal") == "edges" else [f"level-{i + 1}" for i in range(len(P.get("cols", [])))] + (["path"] if P.get("path") else []),
                "about": "a decision tree with its own questions and leaves, or a state diagram with its transitions"},
    "stores":  {"free": True, "steps": lambda P: ["boxes"] + [str(i + 1) for i in range(max([0] + [int(r[0]) for r in P.get("rows", [])] + [int(r[0]) for r in P.get("arrows", [])]))],
                "about": "boxes that hold things and what moves between them: worktrees, LFS, packs, a bundle, two .git layouts"},
    "bars":    {"free": True, "steps": lambda P: _nums(P.get("bars")), "about": "a few numbers as bars"},
    "blame":   {"free": True, "steps": lambda P: ["file", "blame"] + (["after"] if P.get("after") else []), "about": "the lines of a file, each with the commit that last changed it"},
    "todo":    {"free": True, "steps": lambda P: ["list"] + (["edit"] if P.get("edit") else []) + (["result"] if P.get("result") else []), "about": "the todo list of an interactive rebase being edited"},
    "push":    {"free": True, "steps": lambda P: ["refspec", "client", "server"] + (["lease"] if P.get("lease") else []) + ["result"],
                "about": "the anatomy of a push: refspec, two gatekeepers, the lease check"},
    "ladder":  {"free": True, "steps": lambda P: _nums(P.get("rungs") or [0, 1, 2, 3]), "about": "the recovery ladder: reachable, only in the reflog, unreachable, pruned"},
    "cards":   {"free": True, "steps": lambda P: _nums(P.get("cards")) + (["marks"] if P.get("marks") else []), "about": "a few statements as cards, one per step, then ticked, crossed, locked or dimmed"},
    "run":     {"free": True, "steps": lambda P: ["event", "jobs"] + [s for s, k in (("matrix", "matrix"), ("token", "token"), ("data", "artifact"), ("data", "cache"), ("gate", "env"), ("cancel", "concurrency")) if P.get(k)
                                                                    and not (s == "data" and k == "cache" and P.get("artifact"))],
                "about": "a workflow run in detail: event, ref, jobs with needs, matrix, token, cache and artifacts, an environment gate, concurrency"},
}
# names an editor may write instead: the same scenes
TOPIC_ALIASES = {"sequence": "flow", "relay": "flow", "auth": "flow", "oidc": "flow", "handshake": "flow", "hooks": "gates", "checkpoints": "gates", "response": "gates",
                 "ruleset": "layers", "permissions": "layers", "precedence": "layers", "codeowners": "match", "attributes": "match", "includeif": "match",
                 "table": "walk", "decision": "decide", "states": "decide", "lifecycle": "decide", "lfs": "stores", "worktrees": "stores", "packs": "stores", "layouts": "stores",
                 "sizes": "bars", "rebase-todo": "todo", "recovery-ladder": "ladder", "workflow-run": "run"}
# topics that are drawn in the graph notation (several repositories as panels: "[name] ... || [name] ...")
GRAPH_TOPICS = {"repos", "fetch", "prune", "shallow", "partial", "methods", "forks", "submodule", "subtree", "queue", "stale", "pin"}


def _nums(lst):
    return [str(i + 1) for i in range(len(lst or []))]
# where in a paragraph a step should start: at the first of these words (default: the step's own name)
CUE_WORDS = {
    "graph": {"state-1": ["names", "label", "branch", "point"], "state-2": ["after the commit", "first,", "moves", "moved", "follows", "slides", "now "],
              "state-3": ["then ", "second,", "finally", "moves", "moved"]},
    "objects": {"commit": ["commit"], "tree": ["tree"], "blobs": ["blob", "file content"], "second-commit": ["second", "parent", "new tree"],
                "shared": ["isn't stored again", "not stored again", "already exists", "share", "same"], "compare": ["read the rows", "rows", "different id"]},
    "merge": {"check": ["ancestor"], "fast-forward": ["moves", "move ", "fast-forward"], "merge-base": ["neither", "most recent commit", "monday copy", "diverged", "common ancestor", "merge base"],
              "merge": ["true merge", "combine", "third input", "new commit"]},
    "trees": {"edit": ["edit"], "add": ["add"], "commit": ["commit"], "restore": ["restore"], "reset": ["reset"]},
    "sandbox": {"room": ["sealed room", "lab environment", "the lab never", "the room"], "inside": ["inside", "three variables", "redirects"],
                "outside": ["personal", "outside", "on the left", "real configuration"], "enter": ["labs/shell", "walk into", "two arrows", "labs/run"], "doors": ["two doors", "doors"],
                "shield": ["if the labs read", "no arrow", "never read", "never touches", "nothing"]},
    "hash": {"same": ["identical", "same content", "pin the", "same id", "the ids you get"], "different": ["different content", "different ids", "one changed byte", "altered", "different moments", "differ"]},
    "rebase": {"lift": ["lift"], "copy": ["cop", "replay"], "ghost": ["original", "fade"], "move": ["label", "moves"]},
    "remotes": {"teammate-push": ["pushes"], "fetch": ["fetch"], "pull": ["pull"], "commit": ["commit"], "push": ["push"]},
    "reflog": {"reset": ["reset"], "reflog": ["reflog"], "rescue": ["back", "rescue"]},
}
ROW_SCENES = {"reflog"}
ALIASES = {"lab": "sandbox", "sealed-room": "sandbox", "room": "sandbox", "content-addressing": "hash", "ids": "hash", "clock": "hash","commit-graph": "graph", "commits": "graph", "fast-forward": "merge", "ff": "merge", "three-trees": "trees", "tree": "trees",
           "object-model": "objects", "object": "objects", "remote": "remotes", "reflog-rescue": "reflog", "rescue": "reflog",
           "pull-request": "pr", "pullrequest": "pr", "pipeline": "ci", "actions": "ci", "workflow": "ci"}
STEP_SECONDS = 3.2          # how long a scene step is held when nothing is read over it
REF = r"[A-Za-z][\w.@{}~^-]*(?:/[\w.@{}~^-]+)*"


def scene_steps(name, params):
    s = SCENES[name]["steps"]
    if name == "graph":
        return ["grow"] + [st.get("name") or f"state-{i}" for i, st in enumerate(params.get("states", [])) if i]
    if callable(s):
        return list(s(params))
    if isinstance(s, dict):
        return s[params.get("mode", "versus")] + (["after"] if name == "merge" and params.get("mode") == "three-way" and params.get("after") else [])
    return list(s)


def extra_steps(name, params):
    """Steps a scene has but does not play unless the tag lists them in steps=... (so that the tags of v1 play what they always played)."""
    return list(SCENES[name].get("extra", []))


def danger_steps(name, params):
    """The destructive steps of a scene (the mascot worries while one plays); safe=step,step in a tag takes steps off the list."""
    return [x for x in SCENES.get(name, {}).get("danger", []) if x not in (params or {}).get("safe", [])]


def _cue_words(hints, step):
    """The cue words of a step: its list in CUE_WORDS, else its own name.  A step called "1", "2" ... has none: a digit in the
    narration ("2 commits", "version 1") says nothing about the step, so such steps are spread evenly or placed with at_<step>=."""
    return hints.get(step, [] if step.isdigit() else [step.replace("-", " ")])


def spread_steps(scene, steps, start, texts):
    """Which beat plays which step when the script gives no 'step:' tags: a step goes to the first paragraph that names it
    (CUE_WORDS), in order; steps nobody names are spread evenly between their neighbours.  -> steps shown after each beat"""
    m, S = len(texts), len(steps)
    hints = CUE_WORDS.get(scene, {})
    low = [t.lower().replace("`", "") for t in texts]
    at, bi, pos = [None] * S, 0, 0
    for j in range(start, S):
        if j == start and start == 0:
            at[j] = 0; continue
        found = None
        for b in range(bi, m):
            for w in _cue_words(hints, steps[j]):
                p = low[b].find(w, pos if b == bi else 0)
                if p >= 0 and (found is None or (b, p) < found): found = (b, p)
            if found: break
        if found:
            at[j] = found[0]; bi, pos = found[0], found[1] + 1
    for j in range(start, S):                                   # even spread for the steps nobody named
        if at[j] is None:
            lo = at[j - 1] if j > start else 0
            k = next((q for q in range(j + 1, S) if at[q] is not None), None)
            hi = at[k] if k is not None else m - 1
            n = (k if k is not None else S) - j + (1 if k is not None else 0)
            at[j] = min(hi, lo + round((hi - lo) / max(1, n)))
    return [max(start + (1 if start == 0 else 0), start + sum(1 for j in range(start, S) if at[j] <= b)) for b in range(m)]


# parameters whose value is text (an underscore is a space, two underscores are one real underscore) or a comma-separated list
TEXT_KEYS = {"block", "title", "base", "name", "teammate", "note", "trigger", "subject", "alt", "same", "diff", "fn", "runner", "job", "left", "right",
             "rescue_name", "reflog_of", "fn2", "badge", "absent", "review_text", "card", "result_text", "skip_text", "packet", "result", "unit", "question",
             "verdict", "probe", "store", "caption", "header", "gate", "wins_text", "none_text"}
TEXT_LISTS = {"names", "subs", "versions", "chips", "lines", "check_names", "real", "inside",
              "roles", "forms", "badges", "actors", "zones", "columns", "paths", "notes", "labels", "owners", "boxes_text", "path"}
ID_LISTS = {"commits", "trees", "ids", "common", "main_only", "feature_only", "tags", "ghost",
            "upstream_only", "new_ids", "after", "safe", "in", "state", "check_states", "tests", "skip", "base_ids", "missing", "damaged", "pinned", "hl"}
COUNT_KEYS = {"common", "main_only", "feature_only", "upstream_only", "after", "commits"}      # these may also be a number: how many commits
INT_KEYS = {"stop", "back", "start", "incoming", "change", "winner", "pick", "depth", "at_line"}
# rows=a:b:c|d:e:f  a list of records; the number says how many fields a record has (the last field keeps any further colons)
ROW_KEYS = {"rows": 3}


def _list(v):
    """A list value: items are separated by commas, or by | when an item itself contains a comma (lines=a,_b|c ends up as two items)."""
    return [x for x in (v.split("|") if "|" in v else v.split(",")) if x]


GENERIC_DICTS = ("titles", "twig", "point", "at")       # per-step parameters every scene understands, besides say_ and cmd_
GENERIC_KEYS = ("id", "pace")                           # id=name: "step: name.copy" means this scene; pace=quick: steps nobody names follow each other closely
TWIG_POSES = ("pointing", "nod", "careful", "curious", "thinking", "surprised", "worried", "celebrate")


def _spaces(v):
    return v.replace("__", "\0").replace("_", " ").replace("\0", "_")


# key=value.  In the graph notation a ';' ends the value (it separates the parts of a state); in every other scene a ';' between two
# characters belongs to the value (rows=1:A:git_add;_git_commit), and only a ';' at its end is left out.
KV = r"(?<![\w/.-])([a-z][a-z0-9_]*)=([^\s;]+)"
KV_SEMI = r"(?<![\w/.-])([a-z][a-z0-9_]*)=([^\s;]+(?:;+[^\s;]+)*)"


def _read_params(arg_plain, name):
    """The key=value parameters of a tag -> P, or None when an at_<step>= value is not a number."""
    P = {}
    for k, v in re.findall(KV if name == "graph" else KV_SEMI, arg_plain):
        m3 = re.fullmatch(r"(say|cmd|title|twig|point|at|forms)_([a-z0-9_]+)", k)
        if m3 and m3.group(1) == "forms":                 # forms_add=CRLF,LF,LF: the forms of trees change when that step plays
            P.setdefault("forms_steps", {})[m3.group(2).replace("_", "-")] = [_spaces(x) for x in _list(v)]; continue
        if m3 and m3.group(1) in ("say", "cmd"):          # say_commit=One_new_snapshot   cmd_add=off: the caption / command line of one step
            P.setdefault("say" if m3.group(1) == "say" else "cmds", {})[m3.group(2).replace("_", "-")] = _spaces(v)
        elif m3:                                          # title_<step>=New_title  twig_<step>=nod|careful|pointing  point_<step>=name  at_<step>=40 (percent of the paragraph)
            d = {"title": "titles", "twig": "twig", "point": "point", "at": "at"}[m3.group(1)]
            P.setdefault(d, {})[m3.group(2).replace("_", "-")] = _spaces(v) if d in ("titles", "point") else v
        elif k in TEXT_KEYS: P[k] = _spaces(v)
        elif k in TEXT_LISTS: P[k] = [_spaces(x) for x in _list(v)]
        elif k in ID_LISTS and not (k in COUNT_KEYS and v.isdigit()): P[k] = _list(v)
        elif k in ROW_KEYS and name in ROW_SCENES: P[k] = [[_spaces(f) for f in (x.split(":", ROW_KEYS[k] - 1) + [""] * ROW_KEYS[k])[:ROW_KEYS[k]]] for x in _list(v)]
        elif k in INT_KEYS and re.fullmatch(r"-?\d+", v): P[k] = int(v)
        elif k in ("main", "feature", "branch", "onto", "upstream"): P[k] = v.replace("_", " ") if "/" not in v else v
        else: P[k] = v
    try: P.update({"at": {k: max(0.0, min(0.86, float(v) / 100)) for k, v in P["at"].items()}} if "at" in P else {})   # at_<step>=40: percent of the paragraph
    except ValueError: return None
    return P


def parse_tag(rest):
    """'rebase: feature onto main' -> {"scene": "rebase", "params": {...}}   'step: copy' -> {"step": "copy"}   else None."""
    m = re.match(r"\s*([A-Za-z][\w -]*?)\s*(?::\s*(.*))?$", rest.strip().rstrip("."), re.S)
    if not m:
        return None
    name, arg = m.group(1).strip().lower().replace(" ", "-"), (m.group(2) or "").strip()
    arg_plain = CODE_RE.sub(lambda x: x.group(2), arg)
    if name == "step":                                    # "step: copy", or "step: rebase.copy" / "step: <id>.copy" when two scenes have a step of that name
        return {"step": arg_plain.strip().lower().replace(" ", "-")}
    if name in ("end", "off", "close") and not arg:
        return {"end": True}
    if name == "say":                                     # a new caption for the scene that is on screen ("say: off" removes the caption)
        txt = arg_plain.strip()                           # written like a parameter value (no space, underscores): the underscore rule applies
        return {"say": (_spaces(txt) if "_" in txt and " " not in txt else txt) or "off"}
    if name == "twig":                                    # the mascot's pose for the next paragraph: nod, careful, pointing ...
        return {"twig": arg_plain.strip().lower()} if arg_plain.strip().lower() in TWIG_POSES else None
    if name == "replay":                                  # the scene (or the one named: "replay: hash", "replay: <id>") starts again from its first step
        return {"replay": arg_plain.strip().lower()}
    name = ALIASES.get(name, name)
    states_alias = name in ("states", "lifecycle")
    name = TOPIC_ALIASES.get(name, name)
    if name in PRESETS:                                   # bisect, stash, tags: a few parameters are turned into a commit graph with named steps
        raw0 = dict(re.findall(r"(?<![\w/.-])([a-z][a-z0-9_]*)=([^\s;]+)", arg_plain))
        dsl, extra = PRESETS[name](raw0, arg_plain) or (None, None)
        if dsl is None: return None
        if isinstance(dsl, dict): t = {"scene": "graph", "params": dsl}
        else: t = parse_tag("graph: " + dsl)
        if t:
            # the parameters every scene understands are checked against the steps of the preset itself (say_found=..., at_test_1=40)
            passed = _read_params(" ".join(f"{k}={v}" for k, v in raw0.items() if re.fullmatch(r"(title|camera|id|pace|dx|dy)|(say|cmd|title|twig|point|at)_[a-z0-9_]+", k)), "graph")
            if passed is None: return None
            steps = scene_steps("graph", t["params"])
            for k, v in passed.items():
                if k in ("title", "camera", "id", "pace", "dx", "dy", "say", "cmds") + GENERIC_DICTS:
                    if isinstance(v, dict) and any(x not in steps for x in v): return None
                    t["params"][k] = v
            for k, v in (extra or {}).items(): t["params"].setdefault(k, v)
        return t
    if name in GRAPH_TOPICS:
        panels = bool(re.search(r"\[[^\]]*\]|\|\|", arg_plain))
        return parse_tag("graph: " + arg + (" boxes=repos" if "boxes=" not in arg and panels and name != "methods" else "")
                         + (" layout=rows" if "layout=" not in arg and panels and name in ("methods", "queue") else ""))
    if name not in SCENES:
        return None
    if name in ("remotes", "repos") and re.search(r"\[[^\]]*\]|\|\|", arg_plain):
        # "remotes: [your clone] A-B main || [origin] A-B-C main => ..."  repositories as panels, in the graph notation
        t = parse_tag("graph: " + arg + (" boxes=repos" if "boxes=" not in arg else ""))
        if t and "title" not in t["params"] and name == "remotes" and "title=off" not in arg_plain: t["params"]["title"] = "Remotes"
        if t and t["params"].get("title") == "off": del t["params"]["title"]
        return t
    raw = dict(re.findall(KV if name == "graph" else KV_SEMI, arg_plain))
    P = _read_params(arg_plain, name)
    if P is None: return None
    words = re.sub(KV if name == "graph" else KV_SEMI, " ", arg_plain)
    low = words.lower()
    if name == "graph":
        g = graph_from_dsl(words)
        if not g:
            return None
        for k in ("title", "camera", "dx", "dy", "layout", "boxes", "fly", "captions", "settle", "say", "cmds") + GENERIC_DICTS + GENERIC_KEYS:
            if k in P: g[k] = P[k]
        # three or more panels side by side leave each about 500 units: with eight commits in a row the IDs fall below a legible size,
        # so such a picture is stacked (layout=rows) unless the tag says layout=columns
        if "layout" not in P and len(g.get("panels", [])) >= 3 and max(c["col"] for pn in g["panels"] for c in pn["commits"]) >= 7: g["layout"] = "rows"
        if any(k in P for k in ("say", "cmds") + GENERIC_DICTS):   # a caption, a title ... for a step this graph does not have is a typing mistake
            st = scene_steps("graph", g)
            if any(x not in st for d in ("say", "cmds") + GENERIC_DICTS for x in P.get(d, {})): return None
        g["tags"] = sorted(set(g.get("tags", [])) | set(P.get("tags", [])))
        if P.get("ghost"):                                # ghost=id,id: these commits fade in the last state (nothing names them any more)
            g["states"][-1]["ghost"] = [x for x in P["ghost"] if any(c["id"] == x for c in g["commits"])]
        if not g["tags"]: del g["tags"]
        return {"scene": "graph", "params": g}
    if name == "merge":
        ff, tw = re.search(r"fast[- ]forward|\bff\b", low), re.search(r"three[- ]way|3[- ]way|true merge|merge commit", low)
        P["mode"] = "ff" if ff and not tw else ("three-way" if tw and not ff else "versus")
        m2 = re.search(rf"({REF})\s+into\s+({REF})", words)
        if m2: P["feature"], P["main"] = m2.group(1), m2.group(2)
    elif name == "rebase":
        m2 = re.search(rf"({REF})\s+onto\s+({REF})", words)
        if m2: P["branch"], P["onto"] = m2.group(1), m2.group(2)
        if isinstance(P.get("commits"), (list, int)) and "feature_only" not in P: P["feature_only"] = P.pop("commits")     # commits= is the list that is replayed
    elif name == "remotes":
        m2 = re.search(r"\bwith\s+([A-Z][a-z]+)", words)
        if m2: P["teammate"] = m2.group(1)
        if re.search(r"\b(solo|alone|no teammate|only origin|you and origin)\b", low): P["teammate"] = "none"
    elif name == "ci":
        m2 = re.search(r"\b(push|pull_request|schedule|workflow_dispatch|release|merge_group)\b", low)
        if m2 and "event" not in P: P["event"] = m2.group(1)
        m3 = re.search(r"\(([^)]+)\)", words)
        if m3: P["steps"] = [x.strip() for x in m3.group(1).split(",") if x.strip()][:5]
    elif name == "pr":
        m2 = re.search(rf"({REF})\s+into\s+({REF})", words)
        if m2: P["feature"], P["main"] = m2.group(1), m2.group(2)
        if re.search(r"\bblocked\b", low) and "review" not in P and "checks" not in P: P["review"], P["checks"] = "unknown", "unknown"
        if P.get("review") not in (None, "approved", "missing", "changes", "unknown", "off") or P.get("checks") not in (None, "passed", "failing", "pending", "unknown"): return None
        if any(x not in ("passed", "failing", "pending", "unknown", "skipped") for x in P.get("check_states", [])): return None
        if isinstance(P.get("commits"), str) and P["commits"].isdigit(): P["commits"] = int(P["commits"])
    elif name == "reflog":
        m2 = re.search(rf"\bon\s+({REF})", words)
        if m2: P["branch"] = m2.group(1)
    elif name == "objects":
        # commits=916dec3,2e76f67 trees=f3b0ea8,4798110 files=config.yaml:e09e51f>f72ae75,metrics.py:652e0e2 messages=Add_scorer,Raise_temperature
        if "cards" in P:
            return _object_cards(P)
        for k in ("commits", "trees"):
            if k in P: P[k] = P[k][:2]
        if "messages" in P: P["messages"] = [x.replace("_", " ") for x in P["messages"].split(",")][:2]
        if "files" in P:
            files = []
            for item in P["files"].split(","):
                m3 = re.fullmatch(r"([^:]+):([0-9a-f]{4,40})(?:>([0-9a-f]{4,40}))?", item)
                if not m3: return None
                files.append({"name": m3.group(1), "id": m3.group(2), **({"new": m3.group(3)} if m3.group(3) else {})})
            if not 2 <= len(files) <= 4: return None
            P["files"] = files
    if name in BUILDERS:                                  # the schematic scenes: their lists of records are read here
        if states_alias: P.setdefault("reveal", "edges")
        P = BUILDERS[name](P, raw)
        if P is None: return None
    if name == "hash" and P.get("differs") not in ("byte", "date", "parcel"): P["differs"] = "date" if "clock" in rest.lower()[:12] else "byte"
    # Step names in the tag choose the steps.  "trees: add, commit" stops after the last one named (setup, edit, add, commit);
    # a list that starts with the scene's first step is taken literally ("trees: setup, edit, add, commit, reset" skips restore).
    all_steps = scene_steps(name, P)
    known = all_steps + extra_steps(name, P)              # with the steps that play only when steps=... lists them
    for d in ("say", "cmds", "forms_steps") + GENERIC_DICTS:   # a caption or command for a step the scene does not have is a typing mistake
        if any(k not in known for k in P.get(d, {})): return None
    if any(v not in TWIG_POSES for v in P.get("twig", {}).values()): return None
    want = [s for s in all_steps if re.search(rf"(?<![\w-]){re.escape(s)}(?![\w-])", low)]
    out = {"scene": name, "params": P}
    if name in ("merge", "rebase", "reflog"):
        for k in COUNT_KEYS:
            if isinstance(P.get(k), str): P[k] = int(P[k])
    if isinstance(P.get("steps"), str) and (name != "ci" or all(x in known for x in P["steps"].split(",") if x)):   # steps=outside,shield,room: exactly these steps, in this order
        listed = [x for x in P.pop("steps").split(",") if x]
        if not listed or any(x not in known for x in listed): return None
        out["only"] = listed
    elif want and name not in ("merge", "graph") and not SCENES[name].get("free"):
        if want[0] == all_steps[0] and len(want) >= 2: out["only"] = want
        elif want[-1] != all_steps[-1]: out["last"] = want[-1]
    return out


# ---- the graph notation ----------------------------------------------------------------------------------
# One state of one panel is a list of parts separated by ';'.  A part is a chain of commits followed by the names that point at its
# last commit, or one of the keyword parts below.  video/production/ANIMATION_STYLE.md documents the notation for script editors.
MARK_WORDS = ("good", "bad", "skip", "pass", "fail", "left", "right", "same", "dangling", "damaged", "missing", "test", "pruned", "first_bad", "conflict", "rejected")
LIST_PARTS = ("ghost", "dim", "absent", "reflog", "gone")   # ghost: unreachable; dim: not visited; absent: not in this clone; reflog: only the reflog names it; gone: deleted
KEY_PART = re.compile(r"(" + "|".join(MARK_WORDS + LIST_PARTS + ("mark", "note", "role", "range", "range2", "tree", "sub", "say", "cmd", "title", "name", "drop", "view", "link")) + r")\s*:\s*(.*)$")
ID_TOKEN = r"(?:[A-Za-z0-9'′]{1,8}|\*[A-Za-z0-9]{0,6}|\?[\w']{1,40}|\.\.\.[\w]{0,12})"
CHAIN = re.compile(rf"({ID_TOKEN}(?:\s*-+\s*{ID_TOKEN})*)\s*(.*)$")
CHAIN_V1 = re.compile(r"((?:[A-Za-z0-9']{1,7})(?:\s*-+\s*[A-Za-z0-9']{1,7})*)\s*(.*)$")
LABEL_KINDS = {"tag": "tag", "atag": "atag", "branch": "branch", "remote": "remote", "special": "special", "ref": "special"}
MAX_COMMITS = 48
# names Git writes or resolves for itself (ORIG_HEAD, HEAD@{1}, main~2, refs/stash): putting one on a commit does not make it reachable
SPECIAL_NAME = re.compile(r"(HEAD|AUTO_MERGE|\w+_HEAD|refs/.*|.*@\{.*\}|.*[~^]\d*)$")


class _Panel:
    """The commits and states of one panel (one repository) of a graph in the notation."""

    def __init__(self):
        self.commits, self.order, self.tags, self.parsed = {}, [], [], []
        self.rows, self.nrows, self.kinds, self.name = {}, 0, {}, None
        self.extended = False                              # True once anything beyond the v1 notation was used
        self.gone_now = set()                              # commits a "gone:" part removed and no later state brought back

    def state(self, si, stext, inherit):
        commits, order, rows = self.commits, self.order, self.rows
        prev = self.parsed[-1] if self.parsed else None
        st = {"refs": {}, "head": None, "new": [], "ghost": [], "has_ghost": False}
        if inherit and prev:
            st.update({"refs": dict(prev["refs"]), "head": prev["head"], "ghost": list(prev["ghost"]), "has_ghost": prev.get("has_ghost", False)})
            for k in ("dim", "absent", "reflog", "marks", "notes", "roles", "sets", "nohead"):
                if k in prev: st[k] = json.loads(json.dumps(prev[k]))
        refs, new = st["refs"], st["new"]
        chains, ups = [], set()
        glob, named, own = {}, set(), set()                # named: commits this state puts a branch or a tag on; own: the list parts it writes itself
        for part in [p.strip() for p in re.split(r"[;\n]", stext) if p.strip()]:
            m = re.match(r"HEAD\s*(?:=|->)\s*(\S+)$", part)
            if m:
                st["head"] = m.group(1)
                if st["head"].lower() in ("none", "off", "-"):       # HEAD=none: no HEAD in this picture
                    st["head"], st["nohead"] = None, True; self.extended = True
                else: st.pop("nohead", None)
                continue
            m = KEY_PART.match(part)
            if m:
                key, val = m.group(1), m.group(2).strip()
                own.add(key)
                if key == "ghost":
                    st["ghost"] = [x for x in val.split(",") if x]; st["has_ghost"] = True; continue
                self.extended = True
                ids = lambda v: [x for x in v.split(",") if x]
                if key in ("dim", "absent", "reflog", "gone"): st[key] = ids(val)
                elif key in MARK_WORDS:
                    for x in ids(val): st.setdefault("marks", {})[x] = key
                elif key == "mark":                           # mark:word:id,id  any short word as a badge
                    word, _, rest = val.partition(":")
                    for x in ids(rest): st.setdefault("marks", {})[x] = _spaces(word)
                elif key in ("note", "role"):                 # note:ID:free_text   role:ID:base
                    cid, _, txt = val.partition(":")
                    if not txt: return False
                    st.setdefault(key + "s", []).append({"text": _spaces(txt), "at": cid})
                elif key in ("range", "range2"):              # range:id,id,id:label   a shaded set; the label is optional
                    lst, _, lab = val.partition(":")
                    st.setdefault("sets", {})[key] = {"ids": ids(lst), **({"label": _spaces(lab)} if lab else {})}
                    if not lst: del st["sets"][key]
                elif key in ("tree", "sub"):                  # tree:ID:4b825dc   a second line under the commit
                    cid, _, txt = val.partition(":")
                    st.setdefault("_sub", {})[cid] = ("tree " if key == "tree" else "") + _spaces(txt)
                elif key == "drop":                           # drop:name,id  (after '+') removes a label, a note, a role or a mark
                    for x in ids(val):
                        if x not in refs:                         # "drop:v1.0" also removes the label written "atag:v1.0#131e7a7" or "name#2"
                            for r in [r for r in refs if r.split("#")[0] == x]: refs.pop(r)
                        mk = st.get("marks", {})
                        if x not in mk and x not in commits:      # "drop:same", "drop:approved_here": every mark with that word
                            for c in [c for c, w in mk.items() if w in (x, _spaces(x))]: mk.pop(c)
                        refs.pop(x, None); mk.pop(x, None)
                        for k in ("notes", "roles"): st[k] = [n for n in st.get(k, []) if n["text"] != _spaces(x) and n["at"] != x]
                        if st["head"] == x: st["head"] = None
                elif key == "view": st["view"] = ids(val)
                elif key == "link":                           # link:ID>ID:label  an arrow from a commit of this panel to a commit of another panel
                    ab, _, lab = val.partition(":")
                    a, _, b = ab.partition(">")
                    if not a or not b: return False
                    glob.setdefault("links", []).append([a, b, _spaces(lab)])
                else: glob[key] = _spaces(val)                # say, cmd, title, name: they belong to the whole state
                continue
            above = part.startswith("^")                   # '^A-X side': this chain's new commits go on a row above the first row
            if above: part = part[1:].strip()
            m = CHAIN.match(part)
            if not m:
                return False
            if not CHAIN_V1.match(part) or CHAIN_V1.match(part).group(1) != m.group(1): self.extended = True
            ids_ = re.findall(ID_TOKEN, m.group(1))        # "A-...-B": a bare "..." is an unnamed elision, not one named "-B"
            chains.append(ids_)
            if above: ups.add(len(chains) - 1)
            for l in [x for x in re.split(r"[\s,]+", m.group(2)) if x]:
                if l.startswith("(") or l in ("HEAD", "->"): continue
                kind, _, rest = l.partition(":")
                if rest and kind in LABEL_KINDS:
                    l = rest
                    if kind == "tag": self.tags.append(l)
                    else: self.kinds[l] = LABEL_KINDS[kind]; self.extended = True
                if self.kinds.get(l) != "special" and not SPECIAL_NAME.match(l.split("#")[0]): named.add(ids_[-1])
                refs[l] = ids_[-1]
        # edges first: a commit's parents are known before it is placed
        for ids_ in chains:
            for prev_, cid in zip([None] + ids_, ids_):
                if cid not in commits:
                    commits[cid] = {"id": cid, "parents": []}; new.append(cid)
                    if cid.startswith("*"): commits[cid].update({"kind": "anon", "text": ""})
                    elif cid.startswith("?"): commits[cid].update({"kind": "placeholder", "text": _spaces(cid[1:])})
                    elif cid.startswith("..."):
                        w = cid[3:]
                        commits[cid].update({"kind": "elision", "text": (w + " more") if w.isdigit() else _spaces(w)})
                if prev_ and prev_ != cid and prev_ not in commits[cid]["parents"] and cid not in _ancestors(commits, prev_):
                    commits[cid]["parents"].append(prev_)
        for cid, txt in st.pop("_sub", {}).items():
            if cid in commits: commits[cid]["sub"] = txt
        # A state that starts with '+' keeps the lists of the state before it.  Two things end a commit's absence without a word about it:
        # a branch or a tag that this state puts on a commit makes it and its ancestors reachable again (they leave the inherited ghost: and
        # reflog: lists, unless the state writes that list itself), and a commit that was "gone:" returns when a chain names it again.
        if inherit and prev and named:
            back = set(named)
            for c in named: back |= _ancestors(commits, c) if c in commits else set()
            for key in ("ghost", "reflog"):
                if key not in own and st.get(key): st[key] = [x for x in st[key] if x not in back]
        again = [c for ids_ in chains for c in ids_ if c in self.gone_now and c not in st.get("gone", [])]
        if again: st["back"] = list(dict.fromkeys(again))
        self.gone_now = (self.gone_now - set(again)) | set(st.get("gone", []))
        # rows: the first chain is the top row; a later chain that brings new commits opens a new row.  Two exceptions keep a line
        # straight: a merge commit named alone at the end of a chain stays on its first parent's row, and in a later state new
        # commits continue the row of the tip they extend.
        has_child_on_row = lambda c: any(c in x["parents"] and rows.get(x["id"]) == rows.get(c) for x in commits.values() if x["id"] in rows)
        for ci, ids_ in enumerate(chains):
            fresh = [c for c in ids_ if c not in rows]
            if not fresh: continue
            prev_ = ids_[ids_.index(fresh[0]) - 1] if ids_.index(fresh[0]) > 0 else None
            lone_merge = len(fresh) == 1 and len(commits[fresh[0]]["parents"]) >= 2
            if not rows: row = 0
            elif ci in ups: row = min(rows.values()) - 1
            elif prev_ is not None and prev_ in rows and not has_child_on_row(prev_) and (lone_merge or si > 0 or ci == 0): row = rows[prev_]
            else:
                self.nrows += 1; row = self.nrows
            for c in fresh: rows[c] = row
        # order of appearance: as written, but never before a parent
        pending = list(new)
        while pending:
            k = next((c for c in pending if all(p in order for p in commits[c]["parents"])), pending[0])
            pending.remove(k); order.append(k)
        if st["head"] is None and refs and not st.get("nohead"):
            st["head"] = "main" if "main" in refs else next(iter(refs))
        st["new"] = [c for c in order if c in new]
        self.parsed.append(st)
        return glob

    def finish(self):
        """-> ({"commits": [...], "states": [...]} with the first state split in two steps: commits, then labels) or None"""
        commits, order, rows, parsed = self.commits, self.order, self.rows, self.parsed
        if len(commits) < 1 or len(commits) > MAX_COMMITS or not parsed:      # one commit is a picture too (a clone of depth 1)
            return None
        if len(commits) > 12: self.extended = True
        col = {}
        todo = list(order)
        while todo:                                            # to the right of every parent (the longest path from the root)
            c = next((x for x in todo if all(p in col for p in commits[x]["parents"])), None)
            if c is None: return None                          # a commit that is its own ancestor: not a history
            col[c] = 1 + max((col[p] for p in commits[c]["parents"]), default=-1); todo.remove(c)
        top = min(rows.values())                               # rows opened above the first one: the picture still starts at row 0
        out = []
        for c in order:
            d = {"id": c, "col": col[c], "row": rows[c] - top, "parents": commits[c]["parents"]}
            for k in ("kind", "text", "sub"):
                if k in commits[c]: d[k] = commits[c][k]
            out.append(d)
        # two steps for the first state: the commits (what Git recorded), then the labels (the names that point at them)
        states = [{"add": parsed[0]["new"], "refs": {}, "head": None, "notes": []},
                  {"add": [], "refs": parsed[0]["refs"], "head": parsed[0]["head"], "notes": []}]
        for st in parsed[1:]:
            states.append({"add": st["new"], "refs": st["refs"], "head": st["head"], "notes": []})
        for k, st in enumerate([parsed[0]] + parsed):          # the first state is two steps: its ghosts belong to both
            gh = [x for x in st["ghost"] if x in commits]
            if gh: states[k]["ghost"] = gh
            elif any(p["ghost"] or p["has_ghost"] for p in parsed): states[k]["ghost"] = []     # an explicit "no ghosts": a commit that got a name is solid again
            for key in ("dim", "absent", "reflog"):            # like ghosts: a list per state, in both steps of the first state
                if any(key in p for p in parsed): states[k][key] = [x for x in st.get(key, []) if x in commits]
            if st.get("gone") and (k != 1 or len(parsed) == 1): states[k]["gone"] = [x for x in st["gone"] if x in commits]
            if st.get("back") and k > 1: states[k]["back"] = st["back"]
            if any("marks" in p for p in parsed): states[k]["marks"] = {i: w for i, w in st.get("marks", {}).items() if i in commits}
            if any("sets" in p for p in parsed): states[k]["sets"] = {n: dict(v, ids=[x for x in v["ids"] if x in commits]) for n, v in st.get("sets", {}).items()}
            if k != 0:                                         # notes and roles arrive with the labels
                if st.get("notes"): states[k]["notes"] = [n for n in st["notes"] if n["at"] in commits]
                if any("roles" in p for p in parsed): states[k]["roles"] = [n for n in st.get("roles", []) if n["at"] in commits]
            if "view" in st: states[k]["view"] = [x for x in st["view"] if x in commits]
        g = {"commits": out, "states": states}
        if self.tags: g["tags"] = self.tags
        if self.kinds: g["kinds"] = self.kinds
        return g


def _recs(v, n, sep=":"):
    """'a:b:c|d:e:f' -> [[a, b, c], [d, e, f]]: records separated by | (or by commas), n fields each; the last field keeps any further colons."""
    return [[_spaces(f) for f in (x.split(sep, n - 1) + [""] * n)[:n]] for x in _list(v or "")]


VERDICTS = ("pass", "stop", "skip", "bypass", "wait", "done", "ok", "fail", "bad", "pending", "hl", "dim")


def _b_flow(P, raw):
    """flow: actors=Git,helper,server msgs=1>2:get|2>1:username_and_token|1>3:request|3>1:401:fail|1>2:erase"""
    msgs = []
    for a, lab, mk in _recs(raw.get("msgs"), 3):
        m = re.fullmatch(r"(\d)\s*>\s*(\d)", a)
        if not m or (mk and mk not in ("ok", "fail", "wait")): return None
        msgs.append([int(m.group(1)), int(m.group(2)), lab] + ([mk] if mk else []))
    n = len(P.get("actors", []))
    if not 2 <= n <= 5 or not 1 <= len(msgs) <= 8 or any(not 1 <= x <= n for m in msgs for x in m[:2]): return None
    P["msgs"] = msgs
    return P


def _b_gates(P, raw):
    """gates: packet=push_main gates=pre-commit:pass:client:can_stop_the_commit|pre-receive:stop:server zones=your_machine,the_server split=1 result=rejected"""
    gates = [[nm, owner, v or "pass", note] for nm, v, owner, note in _recs(raw.get("gates"), 4)]
    if not 1 <= len(gates) <= 7 or any(g[2] not in ("pass", "stop", "skip", "bypass", "wait", "done") for g in gates): return None
    P["gates"] = gates
    if "split" in P: P["split"] = int(P["split"]) if str(P["split"]).isdigit() else 0
    return P


def _b_layers(P, raw):
    """layers: layers=organization_ruleset:block_force_pushes+1_approval|repository_ruleset:signed_commits+3_approvals result=... rule=must_satisfy"""
    P["layers"] = _recs(raw.get("layers"), 2)
    if not 1 <= len(P["layers"]) <= 6: return None
    if "verdicts" in raw:
        P["verdicts"] = raw["verdicts"].split(",")
        if any(v and v not in ("pass", "fail", "bypass", "skip", "wait") for v in P["verdicts"]): return None
    for k in ("probe", "rule"):
        if k in raw: P[k] = _spaces(raw[k])
    return P


def _b_walk(P, raw):
    """walk: columns=file,base,ours,theirs,result rows=a.txt:v1:v2:v1:v2|b.txt:v1:v1:v3:v3 marks=1.5:ok pick=2"""
    if "columns" in raw:                                      # an empty head ("columns=,base,ours" or "-") keeps its column
        P["columns"] = ["" if x in ("", "-") else _spaces(x) for x in raw["columns"].split("|" if "|" in raw["columns"] else ",")]
    cols = P.get("columns", [])
    rows = _recs(raw.get("rows"), max(1, len(cols)) if cols else 1 + max((x.count(":") for x in _list(raw.get("rows", ""))), default=0))
    if not 1 <= len(rows) <= 9: return None
    P["rows"] = rows
    marks = {}
    for item in [x for x in raw.get("marks", "").split(",") if x]:
        m = re.fullmatch(r"(\d+)\.(\d+):([a-z]+)", item)
        if not m or m.group(3) not in ("ok", "bad", "wait", "hl", "dim"): return None
        marks[f"{m.group(1)}.{m.group(2)}"] = m.group(3)
    if marks: P["marks"] = marks
    return P


def _b_match(P, raw):
    """match: header=.github/CODEOWNERS rules=*:@org/platform|/router/:@org/routing paths=router/classify.py:1+2|README.md:1 wins=last"""
    P["rules"] = _recs(raw.get("rules"), 2)
    P["paths"] = _recs(raw.get("paths"), 2)
    if not 1 <= len(P["rules"]) <= 8 or not 1 <= len(P["paths"]) <= 5 or P.get("wins", "last") not in ("last", "first", "all"): return None
    if any(x and not re.fullmatch(r"\d+(\+\d+)*", x) for _, x in P["paths"]): return None
    if "numbers" in raw: P["numbers"] = raw["numbers"].split(",")
    if "header" in raw: P["header"] = raw["header"].replace("__", "\0").replace("\0", "_") if "/" in raw["header"] or "." in raw["header"] else _spaces(raw["header"])
    return P


def _name(v):
    """A path, a ref or an ID is kept as it is written; other text follows the underscore rule."""
    return v if re.search(r"[/.]|^[0-9a-f]{7,40}$", v) else _spaces(v)


def _depth_cols(ids, edges):
    """Columns for a drawing that reads from left to right: every node one column after the latest node that leads to it (loops are ignored)."""
    depth = {i: 0 for i in ids}
    for _ in range(len(ids)):
        for a, b in edges:
            if a in depth and b in depth and a != b and depth[b] < depth[a] + 1 and depth[a] + 1 < len(ids) and not _reaches(edges, b, a): depth[b] = depth[a] + 1
    return [[i for i in ids if depth[i] == d] for d in range(max(depth.values(), default=0) + 1)]


def _reaches(edges, a, b, seen=None):
    seen = seen or set()
    if a == b: return True
    seen.add(a)
    return any(x == a and y not in seen and _reaches(edges, y, b, seen) for x, y in edges)


def _b_decide(P, raw):
    """decide: nodes=q1:Is_it_committed?|q2:Is_a_label_on_it?|a:git_reflog|b:git_fsck edges=q1>q2:yes|q1>b:no|q2>a:no path=q1,q2,a"""
    nodes = _recs(raw.get("nodes"), 2)
    edges = []
    for ab, lab in _recs(raw.get("edges"), 2):
        a, _, b = ab.partition(">")
        edges.append([a.strip(), b.strip(), lab])
    ids = [n[0] for n in nodes]
    if not 2 <= len(nodes) <= 12 or any(e[0] not in ids or e[1] not in ids for e in edges): return None
    P.update({"nodes": nodes, "edges": edges})
    if P.get("reveal") == "edges":                           # states and transitions: the back edges are part of the picture
        P["cols"] = _depth_cols(ids, [(a, b) for a, b, _ in edges])
    else:
        P["cols"] = _depth_cols(ids, [(a, b) for a, b, _ in edges])
    if "grid" in raw:                                        # grid=open:2.1,closed:3.2  column.row for the nodes you want to place yourself
        grid = {}
        for item in raw["grid"].split(","):
            m = re.fullmatch(r"([^:]+):(\d)\.(\d)", item)
            if not m or m.group(1) not in ids: return None
            grid[m.group(1)] = [int(m.group(2)) - 1, int(m.group(3)) - 1]
        ncol = 1 + max(c for c, _ in grid.values())
        cols = [[] for _ in range(ncol)]
        for i in ids:
            if i in grid: cols[grid[i][0]].append(i)
        for c in cols: c.sort(key=lambda i: grid[i][1])
        rest = [i for i in ids if i not in grid]
        if rest: cols.append(rest)
        P["cols"] = [c for c in cols if c]
        P["grid"] = grid
    if len(P["cols"]) > 5 or any(len(c) > 5 for c in P["cols"]): return None
    if "path" in raw: P["path"] = [x for x in raw["path"].split(",") if x in ids]
    return P


def _b_stores(P, raw):
    """stores: boxes=working_tree:files_you_see|*Git_repository:.git|LFS_store:.git/lfs rows=1:A:model.bin_(2_GB)|2:B:pointer_file@hl|2:C:the_2_GB arrows=2:A1>B1:clean"""
    P["boxes"] = _recs(raw.get("boxes"), 2)
    rows = []
    for st, bx, text in _recs(raw.get("rows"), 3):
        m = re.fullmatch(r"(.*)@(hl|ok|bad|dim|ghost|ref)", text)
        if not st.isdigit() or not re.fullmatch(r"[A-Da-d]", bx): return None
        rows.append([int(st), bx.upper(), m.group(1) if m else text] + ([m.group(2)] if m else []))
    arrows = []
    for st, ab, lab in _recs(raw.get("arrows"), 3):
        a, _, b = ab.partition(">")
        if not st.isdigit() or not re.fullmatch(r"[A-Da-d]\d?", a.strip()) or not re.fullmatch(r"[A-Da-d]\d?", b.strip()): return None
        arrows.append([int(st), a.strip().upper(), b.strip().upper(), lab])
    if not 1 <= len(P["boxes"]) <= 4 or len(rows) > 24 or any(ord(r[1]) - 65 >= len(P["boxes"]) for r in rows) or max([0] + [r[0] for r in rows + arrows]) > 9: return None
    if any(sum(1 for r in rows if r[1] == chr(65 + i)) > 7 for i in range(len(P["boxes"]))): return None
    P["rows"], P["arrows"] = rows, arrows
    return P


def _b_bars(P, raw):
    """bars: bars=before:412|after_gc:96|after_repack_-ad:71 unit=MB"""
    P["bars"] = _recs(raw.get("bars"), 2)
    try: [float(b[1]) for b in P["bars"]]
    except ValueError: return None
    return P if 1 <= len(P["bars"]) <= 8 else None


def _code_spaces(v):
    """The underscore rule for a line of code: '_' is a space and '__' one real underscore; three (or five ...) before a letter or a digit
    are a space and then the underscores of a name ("x_=___private" is "x = _private"), elsewhere the underscores and then a space."""
    def run(m):
        n, nxt = len(m.group(0)), v[m.end():m.end() + 1]
        if n % 2 == 0: return "_" * (n // 2)
        return " " + "_" * (n // 2) if n == 1 or nxt.isalnum() else "_" * (n // 2) + " "
    return re.sub(r"_+", run, v)


def _b_blame(P, raw):
    """blame: file=router/classify.py lines=53e7f57:def_classify(ticket):|9aa221a:____threshold_=_0.7 after=53e7f57,f3e7ca9"""
    ind = int(raw["indent"]) if raw.get("indent", "").isdigit() else 0
    if "indent" in raw and not 1 <= ind <= 8: return None

    def code(t):
        # Underscores at the start of a line are its indentation, one space each.  With indent=4 only whole steps of 4 are indentation and
        # what is left over follows the underscore rule, so "__NAME" is "_NAME" and "______name" is four spaces and "_name".
        n = len(t) - len(t.lstrip("_"))
        if ind: n -= n % ind
        return " " * n + _code_spaces(t[n:])
    if "from" in raw:                                         # from=41: the number of the first line
        if not raw["from"].isdigit() or not 1 <= int(raw["from"]) <= 99990: return None
        P["from"] = int(raw["from"])
    P["lines"] = [[x.split(":", 1)[0], code(x.split(":", 1)[1]) if ":" in x else ""] for x in _list(raw.get("lines", ""))]
    if not 1 <= len(P["lines"]) <= 9: return None
    if "after" in raw: P["after"] = raw["after"].split(",")
    if "file" in raw: P["file"] = _name(raw["file"])
    return P


def _b_todo(P, raw):
    """todo: todo=pick:a1b2c3d:Add_parser|pick:b2c3d4e:Fix_typo|pick:c3d4e5f:Add_tests edit=pick:a1b2c3d:Add_parser|fixup:b2c3d4e:Fix_typo result=a1b2c3d′"""
    def lines(v):                                             # "fixup:-C_1edd58e:subject" and "fixup_-C:1edd58e:subject" are the same line
        out = []
        for verb, cid, subj in _recs(v, 3):
            m = re.fullmatch(r"(-[cC])\s+(\S+)", cid)
            out.append([verb + " " + m.group(1), m.group(2), subj] if m else [verb, cid, subj])
        return out
    P["todo"] = lines(raw.get("todo"))
    if not 1 <= len(P["todo"]) <= 8: return None
    if "edit" in raw: P["edit"] = lines(raw["edit"])
    if "result" in raw: P["result"] = [_name(x) for x in _list(raw["result"])][:5]
    if "file" in raw: P["file"] = _name(raw["file"])
    return P


def _b_push(P, raw):
    """push: src=main dst=main refspec=refs/heads/main:refs/heads/main local=4e1f5fe remote=9aa221a client=pass server=stop notes=fast-forward,rule_declined lease=9aa221a,810dc2f"""
    for k in ("src", "dst", "refspec", "local", "remote", "new"):
        if k in raw: P[k] = raw[k]
    for k in ("gates", "lease_names"):
        if k in raw: P[k] = [_spaces(x) for x in _list(raw[k])]
    if "lease" in raw: P["lease"] = raw["lease"].split(",")[:2]
    if P.get("client", "pass") not in ("pass", "stop") or P.get("server", "pass") not in ("pass", "stop", "skip") or len(P.get("lease", [1, 2])) != 2: return None
    return P


def _b_ladder(P, raw):
    """ladder: commit=af65a92 rungs=reachable:a_branch_leads_to_it|only_in_the_reflog:git_reflog_lists_it|unreachable:git_fsck_finds_it|pruned:gone"""
    if "rungs" in raw:
        P["rungs"] = _recs(raw["rungs"], 2)
        if not 2 <= len(P["rungs"]) <= 5: return None
    return P


def _b_run(P, raw):
    """run: event=pull_request ref=refs/pull/7/merge sha=135aad1 jobs=lint|test|build:lint+test|deploy:build matrix=test:3.11+3.12+3.13 token=contents:read
    artifact=build>deploy:dist cache=test:uv_cache env=deploy:production:a_required_reviewer concurrency=deploy-main"""
    jobs = [[_name(a), b] for a, b in ([x.split(":", 1)[0], x.split(":", 1)[1] if ":" in x else ""] for x in _list(raw.get("jobs", "")))]
    names = [j[0] for j in jobs]
    if not 1 <= len(jobs) <= 8 or any(d not in names for j in jobs for d in j[1].split("+") if d): return None
    P["jobs"] = jobs
    P["cols"] = _depth_cols(names, [(d, j[0]) for j in jobs for d in j[1].split("+") if d])
    if len(P["cols"]) > 4 or any(len(c) > 4 for c in P["cols"]): return None
    for k in ("event", "ref", "sha", "token", "concurrency"):
        if k in raw: P[k] = raw[k]
    if "matrix" in raw: P["matrix"] = raw["matrix"].split(":", 1)
    if "cache" in raw: P["cache"] = [_name(x) for x in raw["cache"].split(":", 1)]
    if "env" in raw: P["env"] = [_spaces(x) if i == 2 else x for i, x in enumerate((raw["env"].split(":", 2) + ["", ""])[:3])]
    if "artifact" in raw:
        ab, _, nm = raw["artifact"].partition(":")
        a, _, b = ab.partition(">")
        P["artifact"] = [a, b, nm]
        if a not in names or b not in names: return None
    for k in ("matrix", "cache", "env"):
        if k in P and P[k][0] not in names: return None
    return P


def _b_cards(P, raw):
    """cards: question=Why_did_it_merge? cards=No_rule_required_it|A_later_line_took_the_path:keep_this_one_in_mind|It_was_a_draft dim=3 marks=1:ok,2:ok"""
    P["cards"] = _recs(raw.get("cards"), 2)
    if not 1 <= len(P["cards"]) <= 8: return None
    for k in ("dim", "ask"):
        if k in raw: P[k] = [int(x) for x in raw[k].split(",") if x.isdigit()]
    if "marks" in raw:
        P["marks"] = [x.split(":", 1) for x in raw["marks"].split(",") if ":" in x]
        if any(not a.isdigit() or b not in ("ok", "bad", "lock", "ring", "dim", "solid") for a, b in P["marks"]): return None
    return P


BUILDERS = {"cards": _b_cards, "flow": _b_flow, "gates": _b_gates, "layers": _b_layers, "walk": _b_walk, "match": _b_match, "decide": _b_decide, "stores": _b_stores, "bars": _b_bars,
            "blame": _b_blame, "todo": _b_todo, "push": _b_push, "ladder": _b_ladder, "run": _b_run}


# ---- presets: a topic with a few parameters becomes a commit graph in several named states ----------------
def _p_bisect(raw, text):
    """bisect: commits=16 first_bad=11        (or commits=id,id,... good=id bad=id first_bad=id tests=id:good|id:skip|id:bad skip=id counts=off|20,10,5)
    The halving: the range that is left is shaded, the commit under test carries HEAD, commits that are ruled out go dark."""
    v = raw.get("commits", "12")
    ids = v.split(",") if not v.isdigit() else ([chr(65 + i) for i in range(int(v))] if int(v) <= 26 else [f"c{i + 1}" for i in range(int(v))])
    n = len(ids)
    if not 4 <= n <= 40 or len(set(ids)) != n: return None
    ix = lambda k, d: ids.index(raw[k]) if raw.get(k) in ids else (int(raw[k]) - 1 if raw.get(k, "").isdigit() and 1 <= int(raw[k]) <= n else d)
    g, b = ix("good", 0), ix("bad", n - 1)
    f = ix("first_bad", (g + b + 1) // 2)
    if not g < f <= b: return None
    tests = []
    if "tests" in raw:
        for cid, verdict in _recs(raw["tests"], 2):
            if cid not in ids or verdict not in ("good", "bad", "skip"): return None
            tests.append((ids.index(cid), verdict))
    else:
        lo, hi = g, b
        while hi - lo > 1:
            mid = (lo + hi) // 2
            tests.append((mid, "bad" if mid >= f else "good"))
            if mid >= f: hi = mid
            else: lo = mid
    # counts=off: no "N left" anywhere; counts=20,10,5,-,1: the numbers of the transcript, for start, mark-1, mark-2 ... ("-": none at that step).
    # Without counts= the scene counts the commits between the last good and the last bad one, which a skip or Git's own choice can contradict.
    counts = raw.get("counts", "")
    given = counts.split(",") if counts and counts != "off" else None
    if given is not None and any(x != "-" and not x.isdigit() for x in given): return None
    own = given is None and counts != "off"                 # the scene's own arithmetic
    pre = [x for x in raw.get("skip", "").split(",") if x]   # skip=id,id: commits marked "skip" before the first test (git bisect skip)
    if any(x not in ids or not g < ids.index(x) < b for x in pre): return None
    commits = [{"id": c, "col": i, "row": 0, "parents": [ids[i - 1]] if i else []} for i, c in enumerate(ids)]
    lo, hi, marks = g, b, dict({ids[g]: "good", ids[b]: "bad"}, **{x: "skip" for x in pre})
    cnt = lambda k: str(hi - lo) if own else (given[k] if given and k < len(given) and given[k] != "-" else None)
    left = lambda k: {"range": dict({"ids": ids[lo + 1:hi + 1]}, **({"label": f"{cnt(k)} left"} if cnt(k) else {}))}
    dark = lambda: ids[:lo] + ids[hi + 1:]
    states = [{"add": ids, "refs": {}, "head": None, "notes": [], "marks": {}, "sets": {}, "dim": []},
              {"add": [], "refs": {}, "head": None, "notes": [], "marks": dict(marks), "sets": left(0), "dim": dark(), "name": "start",
               "cmd": f"git bisect start {ids[b]} {ids[g]}", "caption": f"One of these {cnt(0)} commits introduced the bug" if cnt(0) else "One of these commits introduced the bug"}]
    for k, (mid, verdict) in enumerate(tests):
        states.append({"add": [], "refs": {}, "head": ids[mid], "notes": [], "marks": dict(marks, **{ids[mid]: "test"}), "sets": left(k), "dim": dark(), "name": f"test-{k + 1}",
                       "caption": f"Git checks out the middle of what is left: {ids[mid]}" if "tests" not in raw else f"Git checks out {ids[mid]}"})
        marks[ids[mid]] = verdict
        if verdict == "bad": hi = mid
        elif verdict == "good": lo = mid
        c = cnt(k + 1)
        states.append({"add": [], "refs": {}, "head": ids[mid], "notes": [], "marks": dict(marks), "sets": left(k + 1), "dim": dark(), "name": f"mark-{k + 1}",
                       "cmd": f"git bisect {verdict}", "caption": (f"{ids[mid]} is {verdict}" + (f": {c} left" if c else "")) if verdict != "skip" else f"{ids[mid]} cannot be tested: Git picks a neighbour"})
    marks = {k: v for k, v in marks.items() if k != ids[hi]}
    marks[ids[hi]] = "first_bad"
    states.append({"add": [], "refs": {}, "head": ids[hi], "notes": [], "marks": marks, "sets": {"range": {"ids": [ids[hi]]}}, "dim": [x for x in ids if x != ids[hi] and x != ids[max(lo, 0)]], "name": "found",
                   "caption": f"{ids[hi]} is the first bad commit" + (f", found in {len(tests)} tests instead of {b - g}" if own else "")})
    return {"commits": commits, "states": states, "dx": max(92, min(190, round(1500 / max(1, n - 1)))), "title": "Bisect: halve what is left", "settle": "on"}, {}


def _p_stash(raw, text):
    """stash: commits=6eab4a9,23b0907 index=c1d2e3f stash=f5192c8 on main        A stash entry is two commits: the index, and the working tree on top of it."""
    ids = raw.get("commits", "A,B").split(",")
    m = re.search(rf"\bon\s+({REF})", text)
    br, ix, st = raw.get("branch") or (m.group(1) if m else "main"), raw.get("index", "I"), raw.get("stash", "W")
    tip = ids[-1]
    dsl = (f"{'-'.join(ids)} {br}; HEAD={br}"
           f" => + {tip}-{ix}; {ix}-{st} special:refs/stash; {tip}-{st}; note:{ix}:the_index; note:{st}:the_working_tree; cmd:git_stash; name:stash;"
           f" say:A_stash_entry_is_two_commits:_your_index,_and_your_working_tree_on_top_of_it")
    if raw.get("pop", "on") != "off":
        dsl += f" => + drop:refs/stash; drop:{ix}; drop:{st}; ghost:{ix},{st}; cmd:git_stash_pop; name:pop; say:pop_applies_the_changes_and_deletes_the_entry:_nothing_names_the_two_commits_now"
    return dsl, {"title": "What a stash is"}


def _p_tags(raw, text):
    """tags: commits=d4c9fab,bb904cd,191bbd1 light=v0.9@bb904cd annotated=v1.0@191bbd1#9f3c2a1 on main
    A lightweight tag is a ref that points at a commit; an annotated tag points at a tag object, which points at the commit."""
    ids = raw.get("commits", "A,B,C").split(",")
    m = re.search(rf"\bon\s+({REF})", text)
    br = raw.get("branch") or (m.group(1) if m else "main")
    lt, at = raw.get("light", f"v0.9@{ids[max(0, len(ids) - 2)]}"), raw.get("annotated", f"v1.0@{ids[-1]}")
    ln, _, lc = lt.partition("@")
    an, _, rest = at.partition("@")
    ac, _, oid = rest.partition("#")
    if lc not in ids or ac not in ids: return None
    dsl = (f"{'-'.join(ids)} {br}; HEAD={br}"
           f" => + {lc} tag:{ln}; name:lightweight; say:A_lightweight_tag_is_a_name_that_points_straight_at_a_commit"
           f" => + {ac} atag:{an}{'#' + oid if oid else ''}; name:annotated; say:An_annotated_tag_points_at_a_tag_object,_and_that_object_points_at_the_commit")
    return dsl, {"title": "Two kinds of tag"}


PRESETS = {"bisect": _p_bisect, "stash": _p_stash, "tags": _p_tags}


def _object_cards(P):
    """objects: cards=tag:9f3c2a1:object_a1f3c9e+type_commit,commit:a1f3c9e:tree_4b82d10,tree:4b82d10:100644_blob_91c0e2b_README.md+040000_tree_c3d95d4_src
    refs=v1.0>9f3c2a1,main>a1f3c9e missing=91c0e2b      Cards are separated by commas (or |), their rows by +.  A row that contains the ID of another
    card points at it; the cards are laid out in columns by how far they are from the cards nothing points at."""
    cards = []
    for item in _list(P["cards"]):
        f = item.split(":", 2)
        if len(f) < 2 or not f[0] or not f[1]: return None
        cards.append({"kind": f[0].lower(), "id": f[1], "rows": [_spaces(r) for r in (f[2] if len(f) > 2 else "").split("+") if r]})
    if not 1 <= len(cards) <= 9: return None
    links = []
    for a, c in enumerate(cards):
        for r, row in enumerate(c["rows"]):
            for b, d in enumerate(cards):
                if a != b and len(d["id"]) >= 4 and re.search(rf"(?<![0-9a-f]){re.escape(d['id'][:7])}", row) and not any(l[0] == a and l[2] == b for l in links):
                    links.append([a, r, b])
    depth = [0] * len(cards)
    for _ in range(len(cards)):                             # the longest path from a card nothing points at
        for a, r, b in links:
            if depth[b] < depth[a] + 1 <= len(cards): depth[b] = depth[a] + 1
    depth = [min(d, 2) for d in depth]                       # three columns at most: what lies deeper stands under its parent, in the last column
    levels = [[i for i in range(len(cards)) if depth[i] == d] for d in range(max(depth) + 1)]
    if any(len(l) > 4 for l in levels): return None
    refs = []
    for item in _list(P.get("refs", "")) if isinstance(P.get("refs"), str) else []:
        nm, _, cid = item.partition(">")
        i = next((k for k, c in enumerate(cards) if c["id"] == cid), None)
        if i is None: return None
        refs.append([nm, i])
    out = {"cards": cards, "levels": levels, "links": links}
    if refs: out["refs"] = refs
    if isinstance(P.get("signed"), str):                     # signed=ID:1-3  the rows of a card that a signature covers
        m = re.fullmatch(r"([^:]+):(\d+)-(\d+)", P["signed"])
        if not m: return None
        out["signed"] = [[m.group(1), int(m.group(2)), int(m.group(3))]]
        if "signed_text" in P: out["signed_text"] = _spaces(P["signed_text"])
    for k in ("missing", "damaged", "title", "camera", "say", "cmds") + GENERIC_DICTS + GENERIC_KEYS:
        if k in P: out[k] = P[k]
    steps = scene_steps("objects", out)
    if any(x not in steps for d in ("say", "cmds") + GENERIC_DICTS for x in out.get(d, {})): return None
    return {"scene": "objects", "params": out}


def graph_from_dsl(text):
    """'A-B-C main; B-D-E feature; HEAD=main'  -> graph scene parameters: first the commits, then the labels.
    'state => state' adds later states of the same graph: new commits grow, labels slide to where the new state puts them
    (steps grow, state-1, state-2 ...).  A label written 'tag:name' is drawn as a tag (v1.2.3 is recognised by itself).
    A commit is drawn to the right of all its parents, so 'A-B-M main; A-C-D feature; D-M' is a merge of B and D.
    Beyond v1: '[name] ... || [name] ...' draws several panels (repositories) side by side; a state that starts with '+' keeps
    everything of the state before it and changes only what it names; the keyword parts of KEY_PART add marks, notes, roles,
    shaded ranges, dim / absent / ghost commits, a caption (say:), a command line (cmd:), a title (title:) and a step name (name:)."""
    stexts = [p for p in re.split(r"\s*=>\s*", text) if p.strip()]
    if not stexts:
        return None
    npan = max(len(st.split("||")) for st in stexts)
    panels = [_Panel() for _ in range(npan)]
    globs = []
    for si, stext in enumerate(stexts):
        parts = [x.strip() for x in stext.split("||")]
        whole = stext.strip().startswith("+")                  # '+ ...' continues the state before it
        glob = {}
        for pi, pan in enumerate(panels):
            ptext = parts[pi] if pi < len(parts) else ""
            if pi == 0 and whole: ptext = ptext[1:].strip()
            inherit = whole
            m = re.match(r"\[([^\]]*)\]\s*", ptext)
            if m:
                if pan.name is None: pan.name = _spaces(m.group(1).strip())
                ptext = ptext[m.end():]
            if ptext.startswith("+"): inherit, ptext = True, ptext[1:].strip()
            if not ptext.strip() and npan > 1: inherit = True  # a panel left empty stays as it was
            r = pan.state(si, ptext, inherit)
            if r is False: return None
            for l in r.pop("links", []): glob.setdefault("links", []).append([pi] + l)
            glob.update(r)
        globs.append(glob)
    outs = [pan.finish() for pan in panels]
    if any(o is None for o in outs):
        return None
    beyond_v1 = any(pan.extended for pan in panels) or npan > 1 or any(st.strip().startswith("+") for st in stexts) or any(globs)
    if npan == 1:
        g = outs[0]
    else:
        g = {"panels": [{"name": pan.name or "", "commits": o["commits"], **({"kinds": o["kinds"]} if "kinds" in o else {})} for pan, o in zip(panels, outs)],
             "states": [{"p": [o["states"][k] for o in outs]} for k in range(len(outs[0]["states"]))]}
        tags = sorted({t for o in outs for t in o.get("tags", [])})
        if tags: g["tags"] = tags
    if beyond_v1: g["settle"] = "on"                          # a state ends when its fades and rings are over (v1 tags keep their timing)
    for k, glob in enumerate([globs[0]] + globs):              # the first state is two steps (commits, then labels)
        st = g["states"][k]
        if "say" in glob and k != 1: st["caption"] = glob["say"]             # "say:off": the caption leaves (the scene removes it)
        if "cmd" in glob and k != 0: st["cmd"] = "" if glob["cmd"].strip().lower() == "off" else glob["cmd"]   # "cmd:off": the command line leaves
        if "title" in glob and k != 1: st["title"] = glob["title"]
        for pi, a, b, lab in glob.get("links", []) if k != 0 and npan > 1 else []:
            q = next((j for j, o in enumerate(outs) if j != pi and any(c["id"] == b for c in o["commits"])), None)
            if q is not None and any(c["id"] == a for c in outs[pi]["commits"]) and not (k == 1 and len(globs) > 1 and False):
                if not any(l[:4] == [pi, a, q, b] for l in g.setdefault("links", [])): g["links"].append([pi, a, q, b, lab, k])
        if "name" in glob and k != 0:
            nm = re.sub(r"[^a-z0-9]+", "-", glob["name"].lower()).strip("-")
            if nm and nm != "grow": st["name"] = nm
    return g


def _ancestors(commits, cid):
    seen, todo = set(), [cid]
    while todo:
        c = todo.pop()
        for p in commits[c]["parents"]:
            if p not in seen: seen.add(p); todo.append(p)
    return seen


# ---- ASCII commit graphs ---------------------------------------------------------------------------------
COMMON_REFS = {"main", "master", "HEAD", "ORIG_HEAD", "FETCH_HEAD", "MERGE_HEAD", "rescue", "feature", "topic", "dev", "develop", "release",
               "hotfix", "production", "staging", "trunk"}
TOKEN = re.compile(r"(?<![\w/.@{~'])([0-9a-f]{7}|[A-Z]['′]?\d?|o)(?![\w/.'′@{~])")
HEX7 = re.compile(r"[0-9a-f]{7}$")


def _split_panels(lines):
    """-> [(caption or None, [lines])].  Side by side ('Before   After ...') or one above the other."""
    body = [l for l in lines]
    while body and not body[0].strip(): body.pop(0)
    if not body:
        return None
    def is_text(l):
        return bool(l.strip()) and not re.search(r"[0-9A-Za-z'.]-{2,}[0-9A-Za-z.+(]", l) and not re.fullmatch(r"[\s^|/\\v]+", l)
    first = body[0]
    segs = [(m.start(), m.group(0).strip()) for m in re.finditer(r"\S(?:.*?\S)?(?=\s{3,}|$)", first)]
    if is_text(first) and len(segs) >= 2 and len(body) > 1 and not TOKEN.search(first.replace('HEAD', '')):
        starts = [s for s, _ in segs]
        panels = []
        for k, (s, cap) in enumerate(segs):
            e = starts[k + 1] if k + 1 < len(starts) else None
            part = []
            for l in body[1:]:
                if e is not None and len(l) > e - 1 and l[e - 2:e].strip():
                    return None                           # something runs across the panel boundary
                part.append(l[s:e] if e is not None else l[s:])
            if k == 0: part = [l[:e] if e is not None else l for l in body[1:]]   # the first panel owns what is left of its caption
            panels.append((cap.rstrip(":"), part))
        return panels
    # stacked panels: a caption line, a block, a blank line, a caption line, a block
    blocks, cur, cap = [], [], None
    i = 0
    while i < len(body):
        l = body[i]
        prev_blank = i == 0 or not body[i - 1].strip()
        nxt = next((x for x in body[i + 1:] if x.strip()), "")
        if is_text(l) and prev_blank and not l.startswith(" " * 4) and not is_text(nxt) and "^" not in l:
            if cur and any(x.strip() for x in cur): blocks.append((cap, cur))
            cap, cur = l.strip().rstrip(":"), []
        else:
            cur.append(l)
        i += 1
    if cur and any(x.strip() for x in cur): blocks.append((cap, cur))
    return blocks


def _parse_labels(text):
    """'main   (HEAD -> main)' / 'feature/x, origin/x' / 'main (HEAD)'  -> (refs, head) or None when it is prose."""
    t = text.strip()
    head = None
    m = re.search(r"\(\s*HEAD\s*->\s*([^)\s]+)\s*\)", t)
    if m:
        head = m.group(1); t = (t[:m.start()] + " " + t[m.end():]).strip()
    paren_head = re.search(r"\(\s*HEAD\s*\)", t)
    if paren_head:
        t = (t[:paren_head.start()] + " " + t[paren_head.end():]).strip()
    names = [x for x in re.split(r"[\s,]+", t) if x]
    if not names and head:
        names = [head]
    if not names or len(names) > 3:
        return None
    for n in names:
        if not (re.fullmatch(REF, n) and (n in COMMON_REFS or "/" in n or "-" in n or "_" in n or re.fullmatch(r"v\d[\w.]*", n) or n == head)):
            return None
    refs = [n for n in names if n != "HEAD"]
    if paren_head and refs: head = refs[-1]
    if "HEAD" in names and not head: head = "@"            # detached: HEAD sits on the commit itself
    if head and head != "@" and head not in refs: refs.append(head)
    return refs, head


def _parse_panel(lines):
    """One drawing -> {"commits": {id: {...}}, "refs", "head", "notes"} or None."""
    lines = [l.rstrip() for l in lines]
    while lines and not lines[-1].strip(): lines.pop()
    while lines and not lines[0].strip(): lines.pop(0)
    if not lines:
        return None
    rails = {}                                             # line index -> list of elements
    for r, l in enumerate(lines):
        toks = [(m.start(1), m.end(1), m.group(1)) for m in TOKEN.finditer(l)]
        dashes = [(m.start(), m.end()) for m in re.finditer(r"-{2,}", l)]
        if not dashes and not toks:
            continue
        # a commit must touch a connector on its line, or be alone on its line next to a diagonal
        good = []
        for s, e, t in toks:
            touch = any(d0 == e or d1 == s for d0, d1 in dashes) or (s >= 3 and l[s - 3:s] == "...")
            if touch: good.append((s, e, t))
        if not good and len(toks) >= 1 and not dashes:
            s, e, t = toks[0]
            near = False
            for rr, cc in ((r - 1, s - 1), (r - 1, s - 2), (r + 1, s - 1), (r + 1, s - 2), (r - 1, e), (r + 1, e)):
                if 0 <= rr < len(lines) and 0 <= cc < len(lines[rr]) and lines[rr][cc] in "/\\": near = True
            if near and (HEX7.match(t) or len(lines[r].split()) <= 4): good.append((s, e, t))
        if not good:
            continue
        els = [{"k": "c", "s": s, "e": e, "id": t} for s, e, t in good]
        for d0, d1 in dashes:
            el = {"k": "d", "s": d0, "e": d1}
            if d1 < len(l) and l[d1] in "+." and (d1 + 1 >= len(l) or l[d1 + 1] == " "):
                el["e"] = d1 + 1; el["junction"] = True
            els.append(el)
        els.sort(key=lambda x: x["s"])
        rails[r] = els
    if not rails:
        return None
    commits, order = {}, []
    refs, notes, head = {}, [], None
    consumed = {r: [False] * len(lines[r]) for r in range(len(lines))}

    def mark(r, s, e):
        for c in range(s, min(e, len(lines[r]))): consumed[r][c] = True

    left_of = {}                                           # (rail, dash index) -> commit id at its left / right end
    for r, els in rails.items():
        prev = None
        for k, el in enumerate(els):
            mark(r, el["s"], el["e"])
            if el["k"] == "c":
                cid = el["id"]
                if cid == "o": cid = el["id"] = f"o{r}_{el['s']}"
                if cid in commits and commits[cid]["rail"] != r:
                    return None
                if cid not in commits:
                    commits[cid] = {"id": cid, "x": el["s"], "rail": r, "parents": [], "e": el["e"]}
                    if el["id"].startswith("o") and "_" in cid: commits[cid]["text"] = ""
                    order.append(cid)
                if prev and prev["k"] == "d" and prev.get("left") and prev["e"] == el["s"]:
                    commits[cid]["parents"].append(prev["left"])
                    prev["right"] = cid
            else:
                before = els[k - 1] if k else None
                if before and before["k"] == "c" and before["e"] == el["s"]:
                    el["left"] = before["id"]
                elif before and before["k"] == "d" and before.get("junction") and before["e"] == el["s"] and before.get("left"):
                    el["left"] = before["left"]
                elif el["s"] >= 3 and lines[r][el["s"] - 3:el["s"]] == "...":
                    mark(r, el["s"] - 3, el["s"])
            prev = el
        # text on the rail that is not a commit or a connector: labels (after the last commit) or noise
        l = lines[r]
        last = max((el["e"] for el in els), default=0)
        tail = l[last:]
        if tail.strip():
            last_commit = next((el["id"] for el in reversed(els) if el["k"] == "c"), None)
            if last_commit is None: return None
            pl = _parse_labels(tail)
            if pl:
                for n in pl[0]: refs[n] = last_commit
                if pl[1]: head = last_commit if pl[1] == "@" else pl[1]
            elif len(tail.strip()) <= 64 and not re.search(r"\s{6,}\S", tail.strip()):
                notes.append({"text": re.sub(r"\s+", " ", tail.strip()), "at": last_commit})
            else:
                return None
            mark(r, last, len(l))
        lead = l[:els[0]["s"]]
        if lead.strip() and lead.strip() != "...":
            return None
        mark(r, 0, els[0]["s"])
        for c in range(len(l)):
            if not consumed[r][c] and l[c] != " ":
                if l[c:c + 3] == "..." or l[c] == ".": consumed[r][c] = True
                else: return None

    def at(r, c):
        """The element of rail r that covers or touches column c."""
        for el in rails.get(r, []):
            if el["s"] - 1 <= c <= el["e"]:
                return el
        return None

    def resolve(el, side):
        if el is None: return None
        if el["k"] == "c": return el["id"]
        return el.get("left") if side == "parent" else (el.get("right") or el.get("left") if el.get("junction") else el.get("right"))

    # diagonals
    for r, l in enumerate(lines):
        if r in rails or not re.fullmatch(r"[\s/\\]+", l): continue
        for c, ch in enumerate(l):
            if ch not in "/\\": continue
            consumed[r][c] = True
            up, dn = r - 1, r + 1
            if ch == "/":
                # lower-left end (parent side)
                a_r, a_c = dn, c - 1
                while a_r not in rails and a_r < len(lines) and 0 <= a_c < len(lines[a_r]) and lines[a_r][a_c] == "/": a_r, a_c = a_r + 1, a_c - 1
                b_r, b_c = up, c + 1
                while b_r not in rails and b_r >= 0 and b_c < len(lines[b_r]) and lines[b_r][b_c] == "/": b_r, b_c = b_r - 1, b_c + 1
                if dn < len(lines) and dn not in rails and not (0 <= c - 1 < len(lines[dn]) and lines[dn][c - 1] == "/"): return None
                if up >= 0 and up not in rails and not (c + 1 < len(lines[up]) and lines[up][c + 1] == "/"): return None
                if a_r not in rails or b_r not in rails:
                    if (a_r in rails) != (b_r in rails): return None
                    continue
                A_, B_ = at(a_r, a_c), at(b_r, b_c)
                # which end is older?  the one further left
                pa, ch_ = resolve(A_, "parent"), (B_["id"] if B_ and B_["k"] == "c" else resolve(B_, "child"))
            else:
                a_r, a_c = up, c - 1
                while a_r not in rails and a_r >= 0 and 0 <= a_c < len(lines[a_r]) and lines[a_r][a_c] == "\\": a_r, a_c = a_r - 1, a_c - 1
                b_r, b_c = dn, c + 1
                while b_r not in rails and b_r < len(lines) and b_c < len(lines[b_r]) and lines[b_r][b_c] == "\\": b_r, b_c = b_r + 1, b_c + 1
                if up >= 0 and up not in rails and not (0 <= c - 1 < len(lines[up]) and lines[up][c - 1] == "\\"): return None
                if dn < len(lines) and dn not in rails and not (c + 1 < len(lines[dn]) and lines[dn][c + 1] == "\\"): return None
                if a_r not in rails or b_r not in rails:
                    if (a_r in rails) != (b_r in rails): return None
                    continue
                A_, B_ = at(a_r, a_c), at(b_r, b_c)
                pa, ch_ = resolve(A_, "parent"), (B_["id"] if B_ and B_["k"] == "c" else resolve(B_, "child"))
            if not pa or not ch_ or pa == ch_:
                return None
            if commits[pa]["x"] > commits[ch_]["x"]:
                return None
            if pa not in commits[ch_]["parents"]:
                # only the first diagonal of a chain adds the edge
                commits[ch_]["parents"].append(pa)
    # pointers: a line of carets under a rail, then text at the caret columns
    r = 0
    while r < len(lines):
        l = lines[r]
        if r in rails or not l.strip():
            r += 1; continue
        rest = "".join(ch if not consumed[r][c] else " " for c, ch in enumerate(l))
        if not rest.strip():
            r += 1; continue
        if re.fullmatch(r"[\s^]+", rest):
            up = r - 1
            if up not in rails: return None
            for m in re.finditer(r"\^", rest):
                c = m.start()
                el = next((e for e in rails[up] if e["k"] == "c" and e["s"] - 1 <= c <= e["e"]), None)
                if el is None: return None
                # the text under this caret: the following lines, starting near the caret column
                texts, rr = [], r + 1
                while rr < len(lines) and rr not in rails and lines[rr].strip() and not re.fullmatch(r"[\s^]+", lines[rr]):
                    lead = lines[rr][max(0, c - 2):]
                    seg = re.match(r"\s{0,3}(\S(?:.*?\S)?)(?=\s{3,}|$)", lead)
                    if seg and not all(consumed[rr][max(0, c - 2) + seg.start(1):max(0, c - 2) + seg.end(1)]):
                        texts.append(seg.group(1)); s0 = max(0, c - 2) + seg.start(1)
                        for cc in range(s0, s0 + len(seg.group(1))): consumed[rr][cc] = True
                    rr += 1
                if not texts: return None
                txt = " ".join(texts)
                pl = _parse_labels(txt)
                if pl:
                    for n in pl[0]: refs[n] = el["id"]
                    if pl[1]: head = el["id"] if pl[1] == "@" else pl[1]
                elif len(txt) <= 64:
                    notes.append({"text": re.sub(r"\s+", " ", txt), "at": el["id"]})
                else:
                    return None
                consumed[r][c] = True
            r += 1; continue
        if r - 1 in rails:
            # labels written straight under a commit, without a caret
            okay = True
            for m in re.finditer(r"\S(?:.*?\S)?(?=\s{3,}|$)", rest):
                el = next((e for e in rails[r - 1] if e["k"] == "c" and e["s"] - 2 <= m.start() <= e["e"]), None)
                pl = _parse_labels(m.group(0)) if el else None
                if not pl: okay = False; break
                for n in pl[0]: refs[n] = el["id"]
                if pl[1]: head = el["id"] if pl[1] == "@" else pl[1]
                for cc in range(m.start(), m.end()): consumed[r][cc] = True
            if not okay: return None
        r += 1
    for r, l in enumerate(lines):
        for c, ch in enumerate(l):
            if ch != " " and not consumed[r][c]:
                return None                                # something in the drawing was not understood
    if len(commits) < 2:
        return None
    # every commit except roots needs a parent, and the graph must be one piece
    roots = [c for c in commits.values() if not c["parents"]]
    if len(roots) != 1:
        return None
    if head and head not in refs and head not in commits:
        return None
    # positions: one unit = the usual distance between neighbours on a rail
    gaps = []
    for els in rails.values():
        xs = [e["s"] for e in els if e["k"] == "c"]
        gaps += [b - a for a, b in zip(xs, xs[1:])]
    unit = float(statistics.median(gaps)) if gaps else 10.0
    x0 = min(c["x"] for c in commits.values())
    rail_rows = sorted(rails)
    for c in commits.values():
        c["col"] = round((c["x"] - x0) / unit, 2)
        c["row"] = round((c["rail"] - rail_rows[0]) / 2.0, 2)
    return {"commits": commits, "order": sorted(order, key=lambda i: (commits[i]["col"], commits[i]["row"])), "refs": refs, "head": head, "notes": notes}


def parse_graph(text):
    """An ASCII commit graph -> parameters of the "graph" scene, or None when the drawing is not understood with confidence."""
    lines = text.expandtabs(8).split("\n")
    ind = min((len(l) - len(l.lstrip(" ")) for l in lines if l.strip()), default=0)
    lines = [l[ind:] for l in lines]
    try:
        panels = _split_panels(lines)
        if not panels or len(panels) > 3:
            return None
        parsed = []
        for cap, part in panels:
            p = _parse_panel(part)
            if p is None:
                return None
            parsed.append((cap, p))
    except Exception:
        return None
    commits, states = {}, []
    for k, (cap, p) in enumerate(parsed):
        st = {"add": [], "refs": p["refs"], "head": p["head"], "notes": p["notes"]}
        if cap: st["caption"] = cap
        if k and len(parsed) > 1 and not cap: return None
        moves = []
        for cid in p["order"]:
            c = p["commits"][cid]
            if cid not in commits:
                commits[cid] = {"id": cid, "col": c["col"], "row": c["row"], "parents": c["parents"]}
                if c.get("text") is not None: commits[cid]["text"] = "·"
                st["add"].append(cid)
            else:
                if sorted(commits[cid]["parents"]) != sorted(c["parents"]):
                    return None
                if abs(commits[cid]["col"] - c["col"]) > 0.3 or abs(commits[cid]["row"] - c["row"]) > 0.3:
                    moves.append({"id": cid, "col": c["col"], "row": c["row"]})
        if moves:
            # a whole panel drawn at another offset is not a move: only accept when most commits stayed put
            if len(moves) > len(p["order"]) / 2: return None
            st["moves"] = moves
        gone = [cid for cid in commits if cid not in p["commits"]]
        if gone: st["ghost"] = gone
        states.append(st)
    cols = max(c["col"] for c in commits.values()); rows = max(c["row"] for c in commits.values())
    if len(commits) > 12 or cols > 8 or rows > 3.5:
        return None
    if not any(s["refs"] for s in states):
        return None                                        # a graph without a single label teaches little as an animation
    for c in commits.values():
        if not all(p in commits for p in c["parents"]): return None
    return {"commits": list(commits.values()), "states": states}


# ---- terminal blocks -----------------------------------------------------------------------------------
def term_blocks(lines, mode):
    """Group the lines of a terminal page: a block is a command (with its comment lines and continuation lines) and its output.
    -> list of block numbers, one per line, and the command text of every block."""
    out, cmds, b = [], [], -1
    if mode == "code":
        return [0] * len(lines), [""]
    pending = False
    for k, l in enumerate(lines):
        t = l["t"]
        if t == "cmd":
            if not pending: b += 1; cmds.append("")
            cmds[b] = l["s"]; pending = False
        elif t == "cmt" and _next_is_cmd(lines, k):
            if not pending: b += 1; cmds.append(""); pending = True
        elif b < 0:
            b = 0; cmds.append("")
        out.append(b)
    return out, cmds or [""]


def _next_is_cmd(lines, k):
    for l in lines[k + 1:]:
        if l["t"] == "cmt": continue
        return l["t"] == "cmd"
    return False


# ---- the plan --------------------------------------------------------------------------------------------
VOLATILE = ("n", "caption", "hl", "current", "shown", "progress", "direction", "upto", "source", "danger", "says", "says_before")
RISK_RED = "\U0001F534"


def family_key(s):
    return json.dumps({k: v for k, v in s.items() if k not in VOLATILE}, sort_keys=True, ensure_ascii=False)


def _strip_tags(h):
    return re.sub(r"<[^>]+>", "", h or "")


def _nwords(s):
    return len(re.findall(r"[A-Za-z0-9][\w'./<>=:-]*", s))


def _mentions(tele, keys):
    """Where in the spoken text each key is first mentioned -> [(fraction, key)] in reading order."""
    low, n, out = tele.lower(), max(1, len(tele)), []
    for k in keys:
        variants = [k.lower()]
        if " " in k: variants.append(" ".join(k.lower().split()[:2]))
        pos = min([p for p in (low.find(v) for v in variants) if p >= 0], default=-1)
        if pos >= 0: out.append((pos / n, k))
    return sorted(out)


def _pose(sb, b, s, first_of_section):
    sec = b["section"]
    if s["kind"] == "title": return "hidden"
    if b.get("twig") in TWIG_POSES: return b["twig"]          # "[ANIMATION] twig: nod" before the paragraph
    if RISK_RED in (b.get("tele") or "") or RISK_RED in (b.get("text") or "") or b["anim"].get("danger"): return "worried"
    if b["type"] == "hold" and b.get("why") == "pause": return "thinking"
    if sec == "RECAP": return "celebrate"
    if s["kind"] == "callout" and (sec in ("HOOK", "INTERVIEW QUESTION") or (b.get("tele") or "").rstrip().endswith("?")):
        return "surprised" if (sec == "HOOK" and any(c["fx"] == "callout" for c in b["anim"]["cues"])) else ("curious" if sec == "HOOK" else "thinking")
    if (b.get("tele") or "").rstrip().endswith("?"): return "thinking"
    return "curious"


def annotate(sb):
    """Add beat["anim"] to every beat of a storyboard (in place).  Slides are not changed."""
    slides = {s["n"]: s for s in sb["slides"]}
    beats = sb["beats"]
    fam = [family_key(slides[b["slide"]]) for b in beats]
    i, group = 0, 0
    prev_slide = None
    while i < len(beats):
        j = i
        while j + 1 < len(beats) and fam[j + 1] == fam[i]: j += 1
        run = beats[i:j + 1]
        for b in run: b["anim"] = {"group": group, "cues": []}
        kind = slides[run[0]["slide"]]["kind"]
        {"terminal": _plan_terminal, "bullets": _plan_bullets, "table": _plan_table, "diagram": _plan_diagram,
         "scene": _plan_scene}.get(kind, _plan_simple)(sb, slides, run)
        # a change of picture with no cue of its own (a new caption, a new progress bar) still needs one
        for b in run:
            cues = b["anim"]["cues"]
            if prev_slide is not None and b["slide"] != prev_slide and not any(c["at"] == 0 for c in cues):
                cues.insert(0, {"at": 0, "fx": "still", "state": _state_before(cues)})
            for c in cues:
                c["dissolve"] = bool(c["at"] == 0 and prev_slide is not None and b["slide"] != prev_slide)
            prev_slide = b["slide"]
        group += 1
        i = j + 1
    sec_seen = set()
    for b in beats:
        b["anim"]["pose"] = _pose(sb, b, slides[b["slide"]], b["section"] not in sec_seen)
        sec_seen.add(b["section"])
    sb["anim_version"] = PLAN_VERSION
    return sb


def _state_before(cues):
    """The state a 'still' cue must show: the one the next cue of the beat starts from (or nothing special)."""
    for c in cues:
        if "from" in c and c["from"] is not None: return c["from"]
    return None


FX_OF = {"title": "title", "section": "card", "keypoint": "keypoint", "callout": "callout"}


def _plan_simple(sb, slides, run):
    s = slides[run[0]["slide"]]
    run[0]["anim"]["cues"].append({"at": 0, "fx": FX_OF.get(s["kind"], "still")})


def _plan_bullets(sb, slides, run):
    prev = None
    for b in run:
        s = slides[b["slide"]]
        n = len(s["items"])
        to = {"shown": s.get("shown", n), "current": s.get("current")}
        cues = b["anim"]["cues"]
        item_words = [_nwords(_strip_tags(x)) for x in s["items"]]
        lead_plain = _strip_tags(s.get("lead", ""))
        if to["shown"] == n and to["current"] is None and b["type"] == "narration":
            if (prev is None or prev["shown"] == 0) and s.get("lead") and abs(b["words"] - _nwords(lead_plain)) <= 1 and b is run[0]:
                to = {"shown": 0, "current": None}                 # the lead-in line is read alone: the items wait
            elif (prev is None or prev["shown"] == 0) and n >= 2 and abs(b["words"] - sum(item_words)) <= 2 + 0.12 * sum(item_words):
                # the whole list is read in one go: each item arrives as the voice reaches it
                total, acc = float(sum(item_words)) or 1.0, 0
                for k in range(n):
                    cues.append({"at": round(0.92 * acc / total, 3), "fx": "bullets", "from": prev if k == 0 else {"shown": k, "current": None},
                                 "to": {"shown": k + 1, "current": None}})
                    acc += item_words[k]
                prev = to
                continue
        if prev != to:
            cues.append({"at": 0, "fx": "bullets", "from": prev, "to": to})
        prev = to


def _plan_table(sb, slides, run):
    s0 = slides[run[0]["slide"]]
    n = len(s0["rows"])
    hits = [slides[b["slide"]].get("hl", -1) for b in run]
    named = [h for h in hits if h >= 0]
    progressive = len(set(named)) >= 2 and named == sorted(named) and n >= 3
    prev, top = None, -1
    for k, b in enumerate(run):
        if progressive:
            if hits[k] >= 0: top = max(top, hits[k]); shown = top + 1
            else: shown = 0 if top < 0 else n
            if top >= 0 and hits[k] < 0: top = n - 1
        else:
            shown = n
        to = {"shown": shown}
        if prev != to:
            b["anim"]["cues"].append({"at": 0, "fx": "table", "from": prev, "to": to})
        prev = to
    if prev and prev["shown"] < n:                               # the rows nobody named arrive before the table leaves
        last = run[-1]
        last["anim"]["cues"].append({"at": 0.7, "fx": "table", "from": prev, "to": {"shown": n}})


def _plan_terminal(sb, slides, run):
    s = slides[run[0]["slide"]]
    blk, cmds = term_blocks(s["lines"], s.get("mode", "out"))
    nb = len(cmds)
    # where each block is first named: (index of the beat in the run, fraction)
    where = [(0, 0.0)] + [None] * (nb - 1)
    ptr = (0, 0.0)
    spans = []
    for bi, b in enumerate(run):
        tele = b.get("tele") or ""
        for m in CODE_RE.finditer(tele):
            spans.append((bi, m.start() / max(1, len(tele)), re.sub(r"\s+", " ", m.group(2).strip())))
    for k in range(1, nb):
        cmd = re.sub(r"\s+", " ", cmds[k].strip())
        if not cmd: continue
        for bi, fr, sp in spans:
            if (bi, fr) <= ptr: continue
            if len(sp) >= 6 and (sp in cmd or cmd.startswith(sp)) or (sp == cmd):
                where[k] = (bi, fr); ptr = (bi, fr); break
    # blocks nobody names follow the block before them
    groups = []                                                  # [beat index, fraction, first block, last block + 1]
    for k in range(nb):
        if where[k] is not None: groups.append([where[k][0], where[k][1], k, k + 1])
        else: groups[-1][3] = k + 1
    for gi, (bi, fr, a, e) in enumerate(groups):
        b = run[bi]
        nxt = groups[gi + 1] if gi + 1 < len(groups) else None
        span = ((nxt[1] if nxt and nxt[0] == bi else 1.0) - fr) * b["est"]
        b["anim"]["cues"].append({"at": round(fr if fr else 0, 3), "fx": "terminal", "from": {"blocks": a} if a else None, "to": {"blocks": e},
                                  "budget": round(min(5.0, max(1.2, 0.7 * span)), 2)})


def _plan_diagram(sb, slides, run):
    s = slides[run[0]["slide"]]
    g = s.get("graph")
    if not g:
        run[0]["anim"]["cues"].append({"at": 0, "fx": "draw"})
        return
    states = g["states"]
    keys = [c["id"] for c in g["commits"]]
    for st in states:
        keys += list(st["refs"]) + [n["text"] for n in st.get("notes", [])]
    seen_keys, state = set(), 0
    todo = list(range(1, len(states)))
    for bi, b in enumerate(run):
        cues = b["anim"]["cues"]
        tele = (b.get("tele") or "").replace("`", "")
        if bi == 0:
            cues.append({"at": 0, "fx": "scene", "from": 0, "to": 1})
            state = 1
        if b["type"] != "narration":
            continue
        # later states ("After ...") fire where the narration says their first word, else spread over what is left
        marks = []
        low = tele.lower()
        for k in list(todo):
            cap = (states[k].get("caption") or "").split()
            pos = low.find(cap[0].lower() + ":") if cap else -1
            if pos < 0 and cap:
                m = re.search(rf"\b{re.escape(cap[0].lower())}\b", low)
                pos = m.start() if m else -1
            if pos >= 0:
                marks.append((pos / max(1, len(tele)), k)); todo.remove(k)
        if bi == len(run) - 1 and todo:
            for q, k in enumerate(todo): marks.append((0.45 + 0.4 * q / len(todo), k))
            todo = []
        marks.sort()
        ments = [(fr, k) for fr, k in _mentions(tele, [k for k in dict.fromkeys(keys) if k not in seen_keys]) if fr > 0.08]
        merged = []
        for fr, k in ments:
            seen_keys.add(k)
            if merged and fr - merged[-1][0] < 0.05 and len(merged[-1][1]) < 3: merged[-1][1].append(k)
            else: merged.append((fr, [k]))
        events = [(fr, "state", k) for fr, k in marks] + [(fr, "focus", ks) for fr, ks in merged[:7]]
        for fr, what, v in sorted(events, key=lambda e: e[0]):
            if what == "state":
                cues.append({"at": round(fr, 3), "fx": "scene", "from": state, "to": v + 1}); state = v + 1
            else:
                cues.append({"at": round(fr, 3), "fx": "scene", "from": state, "to": state, "focus": v})


def _step_fractions(scene, names, tele, resumed=False, params=None):
    """Where in the paragraph each step starts: at the first of its cue words that occurs (after the step before it), else
    evenly between its neighbours.  The first step starts with the paragraph unless the scene is already on screen."""
    low, n = tele.lower().replace("`", ""), max(1, len(tele))
    hints = CUE_WORDS.get(scene, {})
    pos, last = [], -1.0
    for k, name in enumerate(names):
        fr = None
        if k or resumed:
            found = []
            for w in _cue_words(hints, name):
                p = low.find(w, int(max(last, 0) * n) + (1 if last >= 0 else 0))
                if p >= 0:
                    found.append(p)
                    if scene != "graph": break            # other scenes: the first cue word of the list that occurs
            if found: fr = min(found) / n                  # a commit graph: whichever of its cue words is spoken first
        if k == 0 and (fr is None or fr < 0.06): fr = 0.0
        if fr is not None and fr > 0.86: fr = None
        if k == 0 and fr is None: fr = 0.0
        pos.append(fr)
        if fr is not None: last = fr
    out = list(pos)
    given = (params or {}).get("at") or {}                  # at_<step>=40: this step starts 40 % into its paragraph
    for k, name in enumerate(names):
        if name in given: out[k] = max(given[name], out[k - 1] if k and out[k - 1] is not None else 0.0)
    quick = (params or {}).get("pace") == "quick"            # pace=quick: steps nobody names follow each other closely instead of spreading over the paragraph
    for k in range(len(out)):
        if out[k] is None:
            lo = out[k - 1] if k else 0.0
            j = next((q for q in range(k + 1, len(out)) if out[q] is not None), None)
            hi = out[j] if j is not None else max(lo, 0.82)
            out[k] = lo + (hi - lo) / ((j - k + 1) if j is not None else max(1, len(out) - k))
            if quick: out[k] = min(out[k], lo + 0.09)
    return [round(min(0.86, x), 3) for x in out]


def _plan_scene(sb, slides, run):
    s0 = slides[run[0]["slide"]]
    prev = s0.get("base", 0)                                   # > 0 when the scene comes back after other slides
    first = True
    said = list(s0.get("says_before", []))                     # captions given by "say:" tags that are already on screen
    for b in run:
        s = slides[b["slide"]]
        upto = s["upto"]
        n = upto - prev
        P = s.get("params") or {}
        says = s.get("says", [])
        if n > 0:
            names = s["steps"][prev:upto]
            fr = _step_fractions(s["scene"], names, b.get("tele") or "", prev > 0, P) if b["type"] == "narration" else [round(0.8 * k / n, 3) for k in range(n)]
            risky = danger_steps(s["scene"], P)
            for k in range(n):
                cue = {"at": fr[k], "fx": "scene", "from": prev + k, "to": prev + k + 1}
                if names[k] in risky: cue["pose"] = "worried"      # the mascot worries while the destructive step plays, not for the whole beat
                if (P.get("point") or {}).get(names[k]): cue["pose"] = "pointing"
                if (P.get("twig") or {}).get(names[k]): cue["pose"] = P["twig"][names[k]]
                b["anim"]["cues"].append(cue)
            said = []
            if says:                                               # a caption given right after the step tag replaces the step's own caption
                b["anim"]["cues"].append({"at": round(min(0.9, fr[-1] + 0.15), 3), "fx": "scene", "from": upto, "to": upto, "says": says, "says_from": 0})
        elif says != said:
            keep = len(said) if says[:len(said)] == said else 0
            b["anim"]["cues"].append({"at": 0, "fx": "scene", "from": upto, "to": upto, "says": says, "says_from": keep})
        elif first and prev:
            b["anim"]["cues"].append({"at": 0, "fx": "still", "state": prev})
        said = list(says)
        prev = upto
        first = False


def main():
    args = sys.argv[1:]
    if args[:1] == ["--graph"]:
        print(json.dumps(parse_graph(open(args[1], encoding="utf-8").read()), indent=1, ensure_ascii=False)); return 0
    if args[:1] == ["--corpus"]:
        import glob, pathlib
        root = pathlib.Path(__file__).resolve().parent.parent / "video" / "production" / "storyboards"
        total = ok = 0
        for p in sorted(glob.glob(str(root / "V*.json"))):
            sb = json.loads(open(p, encoding="utf-8").read())
            for s in sb["slides"]:
                if s["kind"] != "diagram": continue
                total += 1
                g = parse_graph(s["text"])
                if g:
                    ok += 1
                    if "-v" in args: print(sb["id"], s["n"], len(g["commits"]), "commits", len(g["states"]), "state(s)")
        print(f"{ok} of {total} diagram slides parse as commit graphs")
        return 0
    print(__doc__); return 2


if __name__ == "__main__":
    sys.exit(main())
