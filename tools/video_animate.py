#!/usr/bin/env python3
"""Render the animation clips of a storyboard: one short clip per cue (a terminal typing, a row arriving, a scene step).

    python3 tools/video_animate.py V030 V031       these videos (only clips that are missing are rendered)
    python3 tools/video_animate.py --force V030    render every clip again
    python3 tools/video_animate.py --jobs 6 all    number of Chrome processes (default 5)
    python3 tools/video_animate.py --off V030      remove the animation of a video: the builder goes back to still slides
    python3 tools/video_animate.py --plan V030     print the cues without rendering
    python3 tools/video_animate.py --page V030 40  write the pages of beat 40 to the cache, to open them in a browser

Output: video/production/anim/VNNN/anim.json and video/production/anim/VNNN/clips/<id>.mp4
A clip is 1920x1080, 30 fps, and lasts only as long as something moves (usually 0.4 to 2.5 s); its last frame is the picture
that is held until the next cue.  tools/video_build.py puts the clips on the timeline once the narration length is known.

How a clip is made: the slide's own HTML (tools/video_slides.py) plus tools/anim/*.js is opened in headless Chrome;
tools/video_animshoot.mjs sets the time, takes a screenshot, sets the next time ... (no real-time capture); ffmpeg encodes the frames.
"""
import base64, html, json, os, re, shutil, subprocess, sys, time
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parent))
from video_common import *   # noqa: F401,F403
import video_slides, video_animplan

ANIM_VERSION = 2
CLIP_CRF = "13"
POSES = ("curious", "thinking", "surprised", "worried", "celebrate", "pointing", "nod", "careful")
MASCOT_W, MASCOT_H, MASCOT_LOOP, MASCOT_HOP = 170, 200, 60, 12
E = lambda s: html.escape(str(s), quote=False)


def extra_css(pal):
    a = pal["accent"]
    return (f".term .cur{{display:inline-block;width:.6em;height:1.12em;background:{a};vertical-align:text-bottom;margin-left:2px}}"
            ".src{right:210px}"                              # leaves the corner to the mascot
            ".content{transform:scale(.955);transform-origin:0 46%}"   # ... and the right margin: content ends at x = 1746
            "td:first-child,th:first-child{overflow-wrap:normal}"       # a short first cell ("Commit") is not broken mid-word
            "#scene{position:relative}#scene svg{display:block}")


# ---- key points ---------------------------------------------------------------------------------------------
# A key point is one sentence.  The animation layer lays it out in one of four ways, colours its key terms and, when the
# sentence names a concept that has a small drawing, puts that drawing beside it.
GLYPH_WORDS = [   # (glyph, words); the glyph whose word comes first in the sentence wins
    ("warning", r"dangerous|destroy|destroys|lose[sd]?|lost|risk labels?|worst case|mistake|overwrit\w+|force-push\w*|red command"),
    ("lock", r"isolated|sealed|never read|never written|immutab\w+|can't be edited|cannot be edited|pinned|safety net|safe\b|protected|tamper\w*"),
    ("clock", r"clocks?|at one moment|friday|monday copy|on demand|three weeks|every time"),
    ("ladder", r"ladder"),
    ("snapshot", r"snapshots?|photograph\w*|whole project|complete state|whiteboard"),
    ("hash", r"hash\w*|object ids?|commit ids?|\bids?\b|address\w*|warehouse|content addressing|name of a thing"),
    ("merge", r"merge base|merges?|merged|fast-forward\w*|ancestors?|diverged?|common ancestor|monday copy"),
    ("branch", r"branch(es)?|labels?|\brefs?\b|\bhead\b|bookmark|pointer"),
    ("commit", r"commits?"),
    ("folder", r"\.git\b|dot git|folders?|director(y|ies)|objects folder|object database"),
    ("file", r"files?|configuration|config\b|settings|transcripts?|blobs?|bytes"),
    ("terminal", r"commands?|shell|replays?|scripts?|output|type\b|terminal"),
    ("server", r"servers?|remote|origin|machines?|mac\b"),
    ("cloud", r"github's|on github|pull requests?|push\w*|fetch\w*"),
    ("book", r"textbook|book|chapters?|manual|lab \d|exercise"),
    ("target", r"goal|diagnose|predict\w*|answer|verify|first principles"),
]
KEY_TERMS = re.compile("(?i)"
    r"\b(merge base|fast-forward(?:s|ing)?|true merge|merge commit|best common ancestor|common ancestor|ancestor|diverged|snapshots?|"
    r"content addressing|object IDs?|commit IDs?|hash(?:ed|es)?|trees?|blobs?|the index|working tree|HEAD|reflogs?|refs?|branch(?:es)?|"
    r"sandbox|sealed room|fixed clock|real clock|isolated|state|diagnose|verify|prevent|root cause|risk labels?|parents?|"
    r"Already up to date|immutab\w+|deduplication|three-dot|two-dot|packfiles?|remote|origin|pull request|SAFE|CAUTION|DANGEROUS|"
    r"Monday copy|bookmark|photograph|address|worst case|on demand|stored nowhere|nothing is stored|no new object|third input|first principles)\b")
NUM_WORDS = {"two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10, "twelve": 12, "sixteen": 16, "forty": 40, "fifty": 50}
PLAIN = lambda h: html.unescape(re.sub(r"<[^>]+>", "", h or ""))


def _outside_tags(h):
    """Pieces of an HTML fragment: [(text, is_plain_text)], where code spans and tags are not plain text."""
    out, pos = [], 0
    for m in re.finditer(r"<code[^>]*>.*?</code>|<[^>]+>", h, flags=re.S):
        if m.start() > pos: out.append((h[pos:m.start()], True))
        out.append((m.group(0), False)); pos = m.end()
    if pos < len(h): out.append((h[pos:], True))
    return out


def highlight(h, limit=2):
    """Wrap the first key terms of a sentence in <em class="hi">."""
    h = re.sub(r"<b>(.*?)</b>", r'<em class="hi">\1</em>', h)
    left = limit - h.count('<em class="hi">')
    seen, out, inside = set(), [], 0
    for text, plain in _outside_tags(h):
        if not plain:
            inside += text.startswith("<em") - text.startswith("</em")
            out.append(text); continue
        def rep(m):
            nonlocal left
            k = m.group(0).lower().rstrip("s")
            if left <= 0 or inside or k in seen: return m.group(0)
            seen.add(k); left -= 1
            return f'<em class="hi">{m.group(0)}</em>'
        out.append(KEY_TERMS.sub(rep, text))
    return "".join(out)


def pick_glyph(text, avoid=None):
    low, best = text.lower(), None
    for name, pat in GLYPH_WORDS:
        if name == avoid: continue                         # never the same drawing on two key points in a row
        m = re.search(rf"(?<![\w-])(?:{pat})(?![\w-])", low)
        if m and (best is None or m.start() < best[0]): best = (m.start(), name)
    return best[1] if best else None


def split_contrast(h):
    """'A, not B' / 'A instead of B' / 'A rather than B' / 'not A but B' -> (first, second, which one is true, word between) or None."""
    for pat, truth, word in ((r"^(.{12,120}?)[,.:;]\s+not\s+(.{8,120})$", 0, "not"), (r"^(.{12,120}?),?\s+instead of\s+(.{8,120})$", 0, "instead of"),
                             (r"^(.{12,120}?),?\s+rather than\s+(.{8,120})$", 0, "rather than"), (r"^not\s+(.{8,110}?),?\s+but\s+(.{8,120})$", 1, "but")):
        m = re.match(pat, h.strip(), flags=re.I | re.S)
        if not m: continue
        a, b = m.group(1).strip(), m.group(2).strip()
        if any(x.count("<code>") != x.count("</code>") or x.count("<b>") != x.count("</b>") or x.count("<i>") != x.count("</i>") for x in (a, b)): continue
        if len(PLAIN(a)) > 110 or len(PLAIN(b)) > 110 or "?" in PLAIN(a): continue
        b = b.rstrip(".")
        return a[:1].upper() + a[1:], b[:1].upper() + b[1:], truth, word
    return None


# words that end in "s" and are not the things being counted: function words, and verbs after a numbered name ("Gate 3 comes after ...")
_COUNT_NOT_NOUNS = set("as is was has does its this plus less thus us yes always perhaps across unless towards besides sometimes means times minutes "
                       "seconds days weeks hours comes creates gives asks follows needs knows makes takes says goes gets becomes happens remains "
                       "belongs depends differs contains exists appears applies keeps".split())
_COUNT_NOT_FIRST = set("of for and or but she he it that which who to in on at by with the a an is are was were be if so then than when while part "
                       "per from into as".split())
_COUNT_LABELS = (r"(video|videos|section|sections|chapter|part|lab|exercise|step|status|line|rule|page|version|git|python|gate|workflow|level|incident|"
                 r"module|question|phase|row|item|option|case|pattern|rung|stage|figure|table|number|no|q|v|\d\.)$")


def find_count(text):
    """'Four verbs: ...' -> (4, 'verbs') for a sentence that is about a number of things.
    Not for a piece of a larger number ("28,649,024 new secrets"), a numbered name ("Gate 3 comes ..."), a number inside a quoted title,
    or a number followed by words that are not the things counted ("12 as ...", "2 of its ...")."""
    for m in re.finditer(r"(?<![\w.,:/#$%+-])(" + "|".join(NUM_WORDS) + r"|\d{1,3})(?![\d.,:/%]\d)\s+((?:[a-z-]+\s)?[a-z]+s)\b", text, flags=re.I):
        if m.start() > 60: return None
        before = text[:m.start()].lower().rstrip()
        if re.search(_COUNT_LABELS, before): continue
        if text[:m.start()].count('"') % 2 == 1 or (text[:m.start()].count("“") > text[:m.start()].count("”")): continue      # inside a quotation
        n = NUM_WORDS.get(m.group(1).lower()) or int(m.group(1))
        words = m.group(2).strip().split()
        if len(words) == 2 and words[0].lower() in _COUNT_NOT_FIRST: continue
        if len(words) == 2 and (words[1].lower() in _COUNT_NOT_NOUNS or (words[0].lower().endswith("s") and not re.search(r"(ous|ss|us|is)$", words[0].lower()))):
            words = words[:1]                              # "40 engineers runs", "3 commits as": the first word is the thing counted
            if not words[0].lower().endswith("s"): continue
        if n < 2 or n > 99 or words[-1].lower() in _COUNT_NOT_NOUNS: continue
        return n, " ".join(words)
    return None


def keypoint_html(s, k, avoid=None):
    """The body of a key-point slide in the animated layout.  k = how many key points came directly before this one;
    avoid = the glyph of the key point before.  -> (html, glyph or None)"""
    hd, bd, badge = s.get("headline", ""), s.get("body", ""), s.get("badge", "")
    solo = bool(hd and not bd)
    if solo: hd, bd = "", hd
    text = PLAIN(bd)
    n = len(text)
    badge_h = f'<div><span class="kp-badge">{E(badge)}</span></div>' if badge else ""
    hd_h = f'<div class="kp-hd">{hd}</div>' if hd else ""
    rule = '<div class="kp-rule"></div>'
    def size(steps):
        for limit, fs in steps:
            if n < limit: return fs
        return steps[-1][1]
    if text.rstrip().endswith("?") and n <= 150:
        fs = size(((40, 110), (70, 92), (110, 78), (999, 66)))
        return (f'<div class="kp kp-question"><div class="kp-qmark">?</div><div class="kp-text">{badge_h}{hd_h}'
                f'<div class="kp-bd" data-fit="40" style="font-size:{fs}px">{highlight(bd)}</div><div class="kp-rule"></div></div></div>'), None
    con = split_contrast(bd) if not solo else None
    if con:
        a, b, truth, word = con
        m = max(len(PLAIN(a)), len(PLAIN(b)))
        fs = 60 if m < 40 else (52 if m < 70 else 44)
        cls = ("yes", "no") if truth == 0 else ("no", "yes")
        return (f'<div class="kp kp-contrast">{badge_h}{hd_h}<div class="kp-pair" data-fit="30" style="font-size:{fs}px">'
                f'<div class="kp-card {cls[0]}"><div>{highlight(a, 1)}</div></div><div class="kp-mid"><span>{E(word)}</span></div>'
                f'<div class="kp-card {cls[1]}"><div>{highlight(b, 1)}</div></div></div></div>'), None
    cnt = find_count(text)
    if cnt and k % 2 == 0:
        fs = size(((70, 80), (120, 68), (180, 58), (999, 50)))
        return (f'<div class="kp kp-number"><div class="kp-num"><span class="n" data-n="{cnt[0]}">{cnt[0]}</span><span class="u">{E(cnt[1])}</span></div>'
                f'<div class="kp-text">{badge_h}{rule}{hd_h}<div class="kp-bd" data-fit="36" style="font-size:{fs}px">{highlight(bd)}</div></div></div>'), None
    glyph = pick_glyph(text + " . " + PLAIN(hd), avoid)
    if glyph:
        fs = size(((50, 84), (90, 72), (140, 62), (190, 54), (999, 48)))
        art = f'<div class="kp-art"><svg viewBox="0 0 300 300" width="330" height="330" data-glyph="{glyph}"></svg></div>'
        return (f'<div class="kp kp-statement{" left" if k % 2 else ""}"><div class="kp-text">{badge_h}{rule}{hd_h}'
                f'<div class="kp-bd" data-fit="36" style="font-size:{fs}px">{highlight(bd)}</div></div>{art}</div>'), glyph
    fs = size(((50, 96), (90, 82), (140, 70), (190, 60), (999, 52)))
    return (f'<div class="kp kp-statement{" card" if k % 2 else ""}"><div class="kp-text">{badge_h}{rule}{hd_h}'
            f'<div class="kp-bd" data-fit="38" style="font-size:{fs}px">{highlight(bd)}</div></div></div>'), None


def keypoint_css(pal):
    a, a2, b1 = pal["accent"], pal["accent2"], pal["bg1"]
    return f"""
.kp{{width:100%;align-self:stretch;display:flex;align-items:center;gap:70px;padding:0 30px 20px 10px}}
.kp-text{{flex:1;min-width:0}}
.kp-rule{{width:150px;height:9px;background:{a};border-radius:5px;margin-bottom:40px}}
.kp-badge{{display:inline-block;background:{a};color:{b1};font-weight:800;font-size:26px;letter-spacing:3px;border-radius:26px;padding:8px 24px;margin-bottom:30px;text-transform:uppercase}}
.kp-hd{{color:{a};font-weight:800;font-size:44px;line-height:1.2;margin-bottom:.5em}}
.kp-bd{{color:#fff;font-weight:700;line-height:1.21;letter-spacing:-.012em}}
.kp code{{font-family:Menlo,monospace;font-size:.78em;font-weight:700;color:{a2};background:#0b0d12;border:2px solid {a}77;border-radius:.3em;padding:.06em .3em;white-space:nowrap;letter-spacing:0}}
.hi{{font-style:normal;background:linear-gradient({a},{a}) 0 97%/0% .085em no-repeat;-webkit-box-decoration-break:clone;box-decoration-break:clone}}
.kp-art{{flex:none;width:330px;height:330px;filter:drop-shadow(0 14px 22px rgba(0,0,0,.45))}}
.kp.left{{flex-direction:row-reverse}}
.kp.card .kp-text{{background:rgba(11,13,18,.5);border:1px solid #30363d;border-left:12px solid {a};border-radius:22px;padding:54px 60px 58px}}
.kp.card .kp-rule{{display:none}}
.kp-question{{justify-content:center;text-align:center;position:relative;padding:0 120px 10px}}
.kp-question .kp-rule{{margin:44px auto 0}}
.kp-question .kp-bd{{font-weight:800}}
.kp-qmark{{position:absolute;right:40px;top:50%;margin-top:-330px;font:900 660px/1 "Helvetica Neue",Helvetica,Arial;color:{a};opacity:.14;transform-origin:50% 60%}}
.kp-contrast{{flex-direction:column;align-items:stretch;justify-content:center;gap:10px}}
.kp-contrast .kp-hd{{margin-bottom:.9em}}
.kp-pair{{display:flex;align-items:stretch}}
.kp-card{{flex:1;border-radius:24px;padding:50px 48px;font-weight:700;line-height:1.24;display:flex;align-items:center}}
.kp-card.yes{{background:{a}1f;border:4px solid {a};color:#fff}}
.kp-card.no{{background:rgba(11,13,18,.55);border:4px dashed #59636e;color:#aeb8c4}}
.kp-card.no .hi{{background:none}}
.kp-mid{{flex:none;width:170px;display:flex;align-items:center;justify-content:center}}
.kp-mid span{{background:#0b0d12;border:3px solid #59636e;color:#e6edf3;font:800 25px "Helvetica Neue",Helvetica,Arial;letter-spacing:3px;text-transform:uppercase;border-radius:30px;padding:10px 20px;white-space:nowrap}}
.kp-number{{gap:70px}}
.kp-num{{flex:none;min-width:340px;text-align:center}}
.kp-num .n{{display:block;font:900 290px/.92 "Helvetica Neue",Helvetica,Arial;color:{a};letter-spacing:-.04em}}
.kp-num .u{{display:block;font:800 32px "Helvetica Neue",Helvetica,Arial;letter-spacing:5px;text-transform:uppercase;color:#c9d1d9;margin-top:18px}}
"""


# ---- pages ---------------------------------------------------------------------------------------------
def term_pre(s):
    """The lines of a terminal slide, each wrapped so that it can be typed or revealed on its own."""
    blk, _ = video_animplan.term_blocks(s["lines"], s.get("mode", "out"))
    out = []
    for l, b in zip(s["lines"], blk):
        t = l["t"]
        body = video_slides.term_line(l)
        n = video_slides.mono_width(l["s"])
        if t == "cmd":
            body = re.sub(r'^<span class="p">\$ </span>(.*)$', r'<span class="p">$ </span><span class="ty">\1</span>', body, flags=re.S)
        elif t == "more":
            body = re.sub(r"^  (.*)$", r'  <span class="ty">\1</span>', body, flags=re.S)
        out.append(f'<span class="ln" data-b="{b}" data-t="{t}" data-n="{n}">{body}</span>')
    return "\n".join(out)


def page(sb, s, cfg, thumb_uri=None):
    """The HTML of one clip: the slide as the still pipeline draws it, plus the animation script and its instructions."""
    pal = sb["palette"]
    fx = cfg.get("base") or cfg["fx"]
    slide = s
    if fx == "scene" and s["kind"] == "diagram":             # an ASCII commit graph replayed by the graph scene
        slide = {k: v for k, v in s.items() if k not in ("text", "graph")}
        slide.update({"kind": "scene", "scene": "graph", "params": s["graph"], "upto": 0})
    if s["kind"] == "keypoint":
        slide = dict(s, _html=keypoint_html(s, cfg.get("k", 0), cfg.get("avoid"))[0])
    doc = video_slides.slide_html(sb, slide, thumb_uri, scene_script=False)
    if s["kind"] == "terminal":
        doc = _sub_pre(doc, term_pre(s))
    elif s["kind"] == "diagram" and fx == "draw":
        m = re.search(r'(<div class="dia"[^>]*><pre[^>]*>)(.*?)(</pre>)', doc, flags=re.S)
        if m:
            lines = "\n".join(f'<span class="ln">{l if l else " "}</span>' for l in m.group(2).split("\n"))
            doc = doc[:m.start(2)] + lines + doc[m.end(2):]
    inject = (f"<style>{extra_css(pal)}{keypoint_css(pal) if s['kind'] == 'keypoint' else ''}</style><script>{anim_lib()}</script>"
              f"<script>A.run({json.dumps(cfg, ensure_ascii=False, sort_keys=True)})</script>")
    return doc.replace("</body></html>", inject + "</body></html>")


def _sub_pre(doc, inner):
    m = re.search(r'(<div class="term">.*?<pre[^>]*>)(.*?)(</pre>)', doc, flags=re.S)
    return doc[:m.start(2)] + inner + doc[m.end(2):] if m else doc


def full_state(s):
    k = s["kind"]
    if k == "terminal": return {"blocks": len(video_animplan.term_blocks(s["lines"], s.get("mode", "out"))[1])}
    if k == "table": return {"shown": len(s["rows"])}
    if k == "bullets": return {"shown": s.get("shown", len(s["items"])), "current": s.get("current")}
    if k == "scene": return s["upto"]
    if k == "diagram" and s.get("graph"): return len(s["graph"]["states"])
    return None


BASE_FX = {"title": "title", "section": "card", "keypoint": "keypoint", "callout": "callout", "terminal": "terminal", "table": "table",
           "bullets": "bullets", "scene": "scene"}


def cue_cfg(sb, s, cue, progress_from, state_before, k=(0, None)):
    """The instructions handed to the page for one cue."""
    pal = sb["palette"]
    fx = cue["fx"]
    avail_h = video_slides.CONTENT_H - (video_slides.CAPTION_H if s.get("caption") else 0)
    cfg = {"fx": fx, "palette": pal}
    if s["kind"] == "keypoint":
        cfg["k"] = k[0]
        if k[1]: cfg["avoid"] = k[1]
    if fx == "still":
        base = BASE_FX.get(s["kind"]) or ("scene" if s.get("graph") else "draw")
        st = cue.get("state")
        if st is None: st = state_before if state_before is not None else full_state(s)
        if st is None and s["kind"] == "terminal": st = full_state(s)
        cfg.update({"fx": "still", "base": base, "from": st, "to": st})
    else:
        if progress_from is not None: cfg["progress_from"] = progress_from
        for k in ("from", "to", "budget", "focus", "says", "says_from"):
            if k in cue: cfg[k] = cue[k]
    if (cfg.get("base") or fx) == "scene":
        if s["kind"] == "diagram": cfg.update({"scene": "graph", "params": s["graph"], "h": avail_h})
        else: cfg.update({"scene": s["scene"], "params": s.get("params", {}), "steps": s.get("steps"), "h": avail_h, "fit_to": s.get("_fit_to")})
        if s.get("says") and "says" not in cfg and cfg.get("from") == cfg.get("to"):     # a held scene keeps the caption a "say:" tag gave it
            cfg.update({"says": s["says"], "says_from": len(s["says"])})
    return cfg


def plan(vid, sb=None):
    """-> (storyboard, beats [{"cues": [{"at", "clip", "dissolve"}], "group", "pose"}], pages {clip id: html})"""
    sb = sb or load_storyboard(vid)
    if not sb["beats"] or "anim" not in sb["beats"][0]:
        video_animplan.annotate(sb)
    slides = {s["n"]: s for s in sb["slides"]}
    thumb = thumb_path(vid)
    thumb_uri = ("data:image/png;base64," + base64.b64encode(thumb.read_bytes()).decode("ascii")) if thumb else None
    lib_hash = sha1(anim_lib())[:10]
    pages, beats = {}, []
    prev_slide, state, prev_group = None, None, None
    # a scene is framed for the steps this video really plays (a scene that stops early is centred on what it shows)
    reach = {}
    for s in sb["slides"]:
        if s["kind"] == "scene":
            key = json.dumps([s["scene"], s.get("params"), s.get("steps")], sort_keys=True)
            reach[key] = max(reach.get(key, 0), s["upto"])
    for s in sb["slides"]:
        if s["kind"] == "scene":
            s["_fit_to"] = reach[json.dumps([s["scene"], s.get("params"), s.get("steps")], sort_keys=True)]
    kp_run, kp_glyph, kp_avoid = -1, None, None
    for b in sb["beats"]:
        s, a = slides[b["slide"]], b["anim"]
        if a["group"] != prev_group:
            state = None
            kp_run = kp_run + 1 if s["kind"] == "keypoint" else -1
            if s["kind"] == "keypoint":
                kp_avoid = kp_glyph
                kp_glyph = keypoint_html(s, kp_run, kp_avoid)[1]
            else:
                kp_glyph = kp_avoid = None
        prev_group = a["group"]
        cues = []
        for c in a["cues"]:
            pf = prev_slide.get("progress", 0) if (prev_slide is not None and c["at"] == 0 and prev_slide["n"] != s["n"]) else None
            cfg = cue_cfg(sb, s, c, pf, state, (max(kp_run, 0), kp_avoid))
            doc = page(sb, s, cfg, thumb_uri if s["kind"] == "title" else None)
            cid = sha1(f"{ANIM_VERSION}\n{doc}")[:16]
            pages[cid] = doc
            cues.append({"at": c["at"], "clip": cid, "dissolve": bool(c.get("dissolve")), "fx": c["fx"], **({"pose": c["pose"]} if c.get("pose") else {})})
            if "to" in c: state = c["to"]
        beats.append({"i": b["i"], "cues": cues, "group": a["group"], "pose": a.get("pose", "curious"), "slide": b["slide"]})
        prev_slide = s
    return sb, beats, pages, lib_hash


# ---- rendering -----------------------------------------------------------------------------------------
def shoot(jobs, nproc, tag="anim"):
    """jobs: [{"id", "html", "dir", ...}] -> {id: result}.  Several Chrome processes side by side."""
    node = shutil.which("node")
    if not node:
        raise SystemExit("node was not found: the animation layer needs Node (it drives Chrome's DevTools protocol)")
    if not jobs:
        return {}
    CACHE.mkdir(parents=True, exist_ok=True)
    nproc = max(1, min(nproc, len(jobs)))
    chunks = [jobs[i::nproc] for i in range(nproc)]

    def run(ix):
        jp, rp = CACHE / f"{tag}-{os.getpid()}-{ix}.json", CACHE / f"{tag}-{os.getpid()}-{ix}.out.json"
        jp.write_text(json.dumps({"chrome": CHROME, "profile": str(CACHE / f"chrome-{tag}-{os.getpid()}-{ix}"), "fps": FPS, "jobs": chunks[ix]}), encoding="utf-8")
        try:
            subprocess.run([node, str(ROOT / "tools" / "video_animshoot.mjs"), str(jp), str(rp)], capture_output=True, timeout=600 + 30 * len(chunks[ix]))
        except subprocess.TimeoutExpired:
            pass
        out = []
        if rp.exists():
            try: out = json.loads(rp.read_text(encoding="utf-8"))
            except Exception: out = []
        for f in (jp, rp):
            try: f.unlink()
            except OSError: pass
        shutil.rmtree(CACHE / f"chrome-{tag}-{os.getpid()}-{ix}", ignore_errors=True)
        return out

    res = {}
    with ThreadPoolExecutor(nproc) as ex:
        for out in ex.map(run, range(nproc)):
            for r in out: res[r["id"]] = r
    return res


def encode_clip(ff, frames_dir, n, out):
    """JPEG frames -> a short H.264 clip (bt709, limited range, the same as the finished video)."""
    tmp = out.with_suffix(".part.mp4")
    r = subprocess.run([ff, "-y", "-v", "error", "-framerate", str(FPS), "-start_number", "0", "-i", str(frames_dir / "%05d.jpg"), "-frames:v", str(n),
                        "-vf", f"scale={W}:{H}:in_color_matrix=bt601:in_range=pc:out_color_matrix=bt709:out_range=tv,format=yuv420p",
                        "-c:v", "libx264", "-preset", "veryfast", "-crf", CLIP_CRF, "-g", "60", "-pix_fmt", "yuv420p",
                        "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709", "-color_range", "tv",
                        "-r", str(FPS), "-video_track_timescale", "15360", "-an", str(tmp)], capture_output=True, text=True)
    if r.returncode != 0 or not tmp.exists():
        return r.stderr[-300:] or "ffmpeg failed"
    os.replace(tmp, out)
    return None


def clip_frames(fp, path):
    r = subprocess.run([fp, "-v", "error", "-select_streams", "v:0", "-count_frames", "-show_entries", "stream=nb_read_frames,width,height,r_frame_rate",
                        "-of", "json", str(path)], capture_output=True, text=True)
    try:
        st = json.loads(r.stdout)["streams"][0]
        return int(st["nb_read_frames"]), st["width"], st["height"], st["r_frame_rate"]
    except Exception:
        return 0, 0, 0, ""


def manifest_path(vid):
    return ANIM / vid / "anim.json"


def load_manifest(vid):
    p = manifest_path(vid)
    if not p.exists():
        return None
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return None


def animate(vid, force=False, nproc=5, quiet=False):
    """Bring the clips of one video up to date.  -> (manifest, number rendered, problems)"""
    ff = find_tool("ffmpeg")
    if not ff:
        raise SystemExit("ffmpeg is not installed. Install it with:  brew install ffmpeg")
    t0 = time.time()
    sb, beats, pages, lib_hash = plan(vid)
    out = ANIM / vid
    cdir = out / "clips"
    cdir.mkdir(parents=True, exist_ok=True)
    old = load_manifest(vid) or {}
    clips = {} if force else {k: v for k, v in old.get("clips", {}).items() if k in pages and (cdir / f"{k}.mp4").exists()}
    todo = [cid for cid in pages if cid not in clips]
    work = CACHE / "anim" / vid
    shutil.rmtree(work, ignore_errors=True)
    problems = []
    if todo:
        (work / "html").mkdir(parents=True, exist_ok=True)
        jobs = []
        for cid in todo:
            hp = work / "html" / f"{cid}.html"
            hp.write_text(pages[cid], encoding="utf-8")
            jobs.append({"id": cid, "html": str(hp), "dir": str(work / "frames" / cid), "max_frames": 600})
        # long clips first, spread over the Chrome processes
        res = shoot(jobs, nproc)

        def enc(cid):
            r = res.get(cid)
            if not r or not r.get("ok"):
                return cid, None, (r or {}).get("errors") or ["no result from Chrome"]
            err = encode_clip(ff, work / "frames" / cid, r["frames"], cdir / f"{cid}.mp4")
            shutil.rmtree(work / "frames" / cid, ignore_errors=True)
            if err: return cid, None, [err]
            return cid, {"frames": r["frames"], "sfx": r.get("sfx", []), "seconds": r.get("duration", 0)}, None
        with ThreadPoolExecutor(6) as ex:
            for cid, info, err in ex.map(enc, todo):
                if info: clips[cid] = info
                else: problems.append(f"clip {cid}: {'; '.join(str(e) for e in err)[:300]}")
    for p in cdir.glob("*.mp4"):
        if p.stem not in pages: p.unlink()
    man = {"id": vid, "anim_version": ANIM_VERSION, "lib": lib_hash, "script_sha1": sb.get("script_sha1"), "fps": FPS,
           "clips": {k: clips[k] for k in pages if k in clips}, "beats": beats,
           "complete": all(k in clips for k in pages), "rendered_in_seconds": round(time.time() - t0, 1) if todo else old.get("rendered_in_seconds")}
    manifest_path(vid).write_text(json.dumps(man, indent=1), encoding="utf-8")
    if not problems: shutil.rmtree(work, ignore_errors=True)
    if not quiet:
        nfr = sum(clips[c]["frames"] for c in todo if c in clips)
        size = sum(p.stat().st_size for p in cdir.glob("*.mp4")) / 1e6
        print(f"{vid}: {len(pages)} clips, {len(todo)} rendered ({nfr} frames) in {time.time() - t0:.0f} s, {size:.1f} MB"
              + (f", {len(problems)} FAILED" if problems else ""), flush=True)
        for p in problems[:8]: print("   ", p)
    return man, len(todo), problems


def is_animated(vid):
    return manifest_path(vid).exists()


# ---- mascot sprites --------------------------------------------------------------------------------------
def mascot_dir(pal):
    return CACHE / "mascot" / sha1(f"{ANIM_VERSION}|{(ANIM_JS / 'mascot.js').read_text(encoding='utf-8')}|{pal['accent']}|{pal['accent2']}")[:12]


def mascot_sprites(pal, nproc=5):
    """Transparent PNG sprites of the mascot for one palette (made once, kept in the cache).  -> directory"""
    d = mascot_dir(pal)
    n = 3 * MASCOT_LOOP + MASCOT_HOP
    if all((d / p / f"{n - 1:05d}.png").exists() for p in POSES):
        return d
    shutil.rmtree(d, ignore_errors=True)
    (d / "html").mkdir(parents=True, exist_ok=True)
    jobs = []
    for p in POSES:
        hp = d / "html" / f"{p}.html"
        hp.write_text('<!doctype html><html><head><meta charset="utf-8"></head><body>'
                      f"<script>{anim_lib()}</script><script>Mascot.page({json.dumps({'pose': p, 'palette': pal})})</script></body></html>", encoding="utf-8")
        jobs.append({"id": p, "html": str(hp), "dir": str(d / p), "width": MASCOT_W, "height": MASCOT_H, "transparent": True, "format": "png", "max_frames": n})
    res = shoot(jobs, nproc, tag="mascot")
    bad = [p for p in POSES if not res.get(p, {}).get("ok")]
    if bad:
        raise RuntimeError(f"mascot sprites failed for {bad}: {[res.get(p, {}).get('errors') for p in bad]}")
    return d


def main():
    argv = sys.argv[1:]
    force, off, show = "--force" in argv, "--off" in argv, "--plan" in argv
    nproc = 5
    if "--jobs" in argv:
        nproc = int(argv[argv.index("--jobs") + 1]); del argv[argv.index("--jobs"):argv.index("--jobs") + 2]
    args = [a for a in argv if not a.startswith("--")]
    if not args:
        print(__doc__); return 2
    if "--page" in argv:
        vid, beat = vid_norm(args[0]), int(args[1])
        sb, beats, pages, _ = plan(vid)
        d = CACHE / "anim-pages" / vid
        d.mkdir(parents=True, exist_ok=True)
        for k, c in enumerate(beats[beat]["cues"]):
            p = d / f"beat{beat:03d}-cue{k}.html"
            p.write_text(pages[c["clip"]], encoding="utf-8")
            print(f"{p}   (cue at {c['at']}; in the browser console: __anim.seek(0.5))")
        return 0
    ids = expand_ids(args)
    here = pathlib.Path(__file__).resolve().parent
    failed = 0
    for vid in ids:
        if off:
            shutil.rmtree(ANIM / vid, ignore_errors=True); print(f"{vid}: animation removed"); continue
        try:
            import video_storyboard
            if not video_storyboard.up_to_date(vid):
                subprocess.run([sys.executable, str(here / "video_storyboard.py"), vid], check=True, stdout=subprocess.DEVNULL)
            if show:
                sb, beats, pages, _ = plan(vid)
                slides = {s["n"]: s for s in sb["slides"]}
                for b, pb in zip(sb["beats"], beats):
                    cues = "  ".join(f"{c['at']:.2f}:{c['fx']}" + ("~" if c["dissolve"] else "") for c in pb["cues"]) or "(hold)"
                    print(f"{b['i']:4d} #{b['slide']:03d} {slides[b['slide']]['kind']:9s} {pb['pose']:9s} {cues}")
                print(f"{vid}: {len(pages)} clips"); continue
            man, n, problems = animate(vid, force, nproc)
            if problems: failed += 1
        except SystemExit as e:
            print(e); failed += 1
        except Exception as e:
            print(f"{vid}: FAILED: {type(e).__name__}: {e}"); failed += 1
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
