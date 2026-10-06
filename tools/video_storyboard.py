#!/usr/bin/env python3
"""Turn a narration script into a storyboard: an ordered list of beats, each with the slide shown while it is read.

    python3 tools/video_storyboard.py V008 V040      these videos
    python3 tools/video_storyboard.py all            every script that exists (skips up-to-date ones)
    python3 tools/video_storyboard.py --force all    rebuild everything
    python3 tools/video_storyboard.py --dump V008    print a readable outline of the result

Output: video/production/storyboards/VNNN.json

A beat is one unit the narrator reads (a paragraph, a list item, or a list read as one unit) or a silent hold
(title card, section card, [PAUSE], a page of long terminal output).  Each beat names one slide.  A slide is one
distinct visual state; the slide renderer draws one PNG per slide.
"""
import html, json, math, re, sys

sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parent))
from video_common import *   # noqa: F401,F403
import video_animplan

VERSION = 22                      # bump to invalidate every storyboard

# ---- layout numbers shared with the renderer (1920x1080) ---------------------------------------
CONTENT_W, CONTENT_H = 1728, 880         # the content box under the header
CAPTION_H = 132                          # height taken by a caption strip
MONO_ADV = 0.6021                        # Menlo advance width / font size
TERM_FS = (34, 32, 30, 28, 26)           # terminal font sizes tried, largest first; never below 26
TERM_PAD_W, TERM_CHROME_H = 80, 54 + 56  # horizontal padding, title bar + vertical padding
TERM_LH = 1.38
TABLE_FS = (40, 38, 36, 34, 32, 30, 28)
BULLET_FS = (46, 42, 38, 34)
HOLD_TITLE, HOLD_SECTION, HOLD_PAUSE, HOLD_PAGE, HOLD_VISUAL = 2.0, 1.5, 2.0, 3.0, 5.0
HOLD_PREDICT = 4.5                       # a [PAUSE] after "Predict ...", "Say it out loud", "I'll wait": time to really answer
PREDICT_RE = re.compile(r"\b(predict|prediction|say it|out loud|i'll wait|before (the commands?|git|i) |your answer|fast-forward, true merge, or nothing)", re.I)
# words of a stage direction that describe the layout and must never be shown as a label
LAYOUT_WORDS = re.compile(r"^\s*(title card|caption bar|lower[- ]third|callout|full[- ]screen|split layout|split screen|overlay|text on screen|on screen|card|slide)\b\s*[:.]?\s*", re.I)


def clean_label(label):
    prev = None
    while prev != label:
        prev, label = label, LAYOUT_WORDS.sub("", label or "")
    return label.strip().rstrip(":").strip()
LONG_RUN = 45.0                          # seconds one unchanged visual may stay before captions are added
SPLIT_WORDS, CHUNK_WORDS = 90, 60        # paragraphs longer than SPLIT_WORDS are read as several beats

SECTION_RE = re.compile(r"^## ([A-Z][A-Z ,&/'-]+?)\s*$")
DIR_RE = re.compile(r"^\*\*\[(ON SCREEN|TERMINAL|DIAGRAM|PAUSE|ANIMATION)\]\*\*[ \t]*")
LIST_RE = re.compile(r"^(\s*)([-*+]|\d+[.)])\s+(.*)$")
SECREF_RE = re.compile(r"\bsections?\s+(\d+[A-D]?\.\d+)", re.I)
CODE_RE = re.compile(r"(`+)(.+?)\1")
RISK = "\U0001F7E2\U0001F7E1\U0001F534"


# ---- inline Markdown ---------------------------------------------------------------------------
def _stash_code(md):
    """Replace code spans by placeholders so that bold / italic markers around them can be handled."""
    keep = []
    def put(m):
        keep.append(m.group(2).strip()); return f"\x02{len(keep) - 1}\x03"
    return CODE_RE.sub(put, _link_code(md)), keep


def _strip_marks(s):
    s = re.sub(r"!\[([^\]]*)\]\([^)]*\)", r"\1", s)
    s = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", s)
    s = re.sub(r"\*\*(.+?)\*\*", r"\1", s)
    s = re.sub(r"(?<![\*\w])\*(?!\s)([^*]+?)(?<!\s)\*(?![\*\w])", r"\1", s)
    s = re.sub(r"(?<![\w_\x03])_(?!\s)([^_]+?)(?<!\s)_(?![\w_\x02])", r"\1", s)
    return s.replace("\\|", "|").replace("\\*", "*").replace("\\_", "_").replace('\\"', '"')


def _link_code(md):
    """[`code`](url) -> `code` so links around code spans do not survive."""
    return re.sub(r"\[(`[^`]+`)\]\([^)]*\)", r"\1", md)


def tele(md):
    """Teleprompter text: Markdown markers removed, code spans kept in backticks."""
    t, keep = _stash_code(md)
    t = re.sub(r"\x02(\d+)\x03", lambda m: "`" + keep[int(m.group(1))] + "`", _strip_marks(t))
    return re.sub(r"\s+", " ", t).strip()


def plain(md):
    return re.sub(r"\s+", " ", CODE_RE.sub(lambda m: m.group(2), tele(md))).strip()


def inline_html(md):
    """Markdown inline -> small HTML subset (b, i, code)."""
    t, keep = _stash_code(md)
    t = re.sub(r"!\[([^\]]*)\]\([^)]*\)", r"\1", t)
    t = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", t)
    t = html.escape(t, quote=False)
    t = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", t)
    t = re.sub(r"(?<![\*\w])\*(?!\s)([^*]+?)(?<!\s)\*(?![\*\w])", r"<i>\1</i>", t)
    t = t.replace("\\|", "|").replace("\\*", "*").replace("\\_", "_").replace('\\"', '"')
    t = re.sub(r"\x02(\d+)\x03", lambda m: "<code>" + html.escape(keep[int(m.group(1))], quote=False) + "</code>", t)
    return re.sub(r"[ \t\r\n]+", " ", t).strip().replace("\u2028", "<br>")


def words(s):
    return len(re.findall(r"[A-Za-z0-9][\w'./<>=:-]*", plain(s)))


def est_seconds(n_words):
    return round(max(1.2, n_words * 60.0 / WPM), 2)


_ABBR = re.compile(r"\b(e\.g|i\.e|vs|etc|cf|No|Fig|approx|Mr|Ms|Dr)\.$")


def sentences(text):
    """Split teleprompter text into sentences; code spans and quoted strings are not split."""
    keep = []
    def stash(m):
        keep.append(m.group(0)); return f"\x00{len(keep) - 1}\x00"
    t = CODE_RE.sub(stash, text)
    parts, start = [], 0
    for m in re.finditer(r"[.?!][\"”’)]*\s+(?=[\"“(\x00A-Z0-9" + RISK + "])", t):
        seg = t[start:m.end()].strip()
        if _ABBR.search(seg) or len(seg) < 3 or re.search(r"(^|\s)\d+\.$", seg):
            continue
        if seg.count('"') % 2 == 1:          # inside a straight-quoted string
            continue
        parts.append(seg); start = m.end()
    if t[start:].strip():
        parts.append(t[start:].strip())
    return [re.sub(r"\x00(\d+)\x00", lambda m: keep[int(m.group(1))], p) for p in parts]


def first_sentence(md, limit=230):
    s = sentences(tele(md))
    if not s:
        return ""
    out = s[0]
    if len(plain(out)) < 28 and len(s) > 1 and len(plain(out + " " + s[1])) <= limit:
        out = out + " " + s[1]
    if len(out) > limit:
        cut = out[:limit]
        for sep in ("; ", ": ", ", ", " "):
            k = cut.rfind(sep)
            if k > limit * 0.55:
                cut = cut[:k]; break
        if cut.count("`") % 2:
            cut = cut[:cut.rfind("`")].rstrip()
        out = cut.rstrip(" ,;:") + " …"
    return out


def split_long(md):
    """A long paragraph is read as several beats so the teleprompter stays comfortable and the frame can change."""
    t = tele(md)
    n = words(t)
    if n <= SPLIT_WORDS:
        return [t]
    sents = sentences(t)
    k = math.ceil(n / CHUNK_WORDS)
    target = n / k
    chunks, cur, cw = [], [], 0
    for s in sents:
        cur.append(s); cw += words(s)
        if cw >= target * 0.9 and len(chunks) < k - 1:
            chunks.append(" ".join(cur)); cur, cw = [], 0
    if cur:
        if chunks and cw < 12:
            chunks[-1] += " " + " ".join(cur)
        else:
            chunks.append(" ".join(cur))
    return chunks


# ---- block parser (used for scripts and for textbook sections) ---------------------------------
def split_row(line):
    line = line.strip()
    if line.startswith("|"): line = line[1:]
    if line.endswith("|") and not line.endswith("\\|"): line = line[:-1]
    cells, cur, tick, i = [], "", False, 0
    while i < len(line):
        c = line[i]
        if c == "`": tick = not tick
        if c == "\\" and i + 1 < len(line) and line[i + 1] == "|":
            cur += "|"; i += 2; continue
        if c == "|" and not tick:
            cells.append(cur.strip()); cur = ""
        else:
            cur += c
        i += 1
    cells.append(cur.strip())
    return cells


def parse_blocks(lines, base=1):
    """lines -> blocks with 1-based source line numbers."""
    blocks, i, n, snippet = [], 0, len(lines), None
    while i < n:
        ln = lines[i]
        s = ln.strip()
        if not s:
            i += 1; continue
        if s.startswith("```"):
            lang = s[3:].strip().split(" ")[0].lower()
            fence = re.match(r"`+", s).group(0)
            j, body = i + 1, []
            while j < n and not lines[j].strip().startswith(fence):
                body.append(lines[j].rstrip("\n")); j += 1
            blocks.append({"t": "fence", "lang": lang, "text": "\n".join(body), "snippet": snippet, "line": base + i})
            i = j + 1; continue
        if s.startswith("<!--"):
            m = re.match(r"<!--\s*snippet:\s*(\S+)\s*-->", s)
            if m: snippet = m.group(1)
            elif re.match(r"<!--\s*/snippet\s*-->", s): snippet = None
            while i < n and "-->" not in lines[i]: i += 1
            i += 1; continue
        if re.match(r"^#{1,6} ", ln):
            lvl = len(ln) - len(ln.lstrip("#"))
            blocks.append({"t": "h", "level": lvl, "text": ln[lvl:].strip(), "line": base + i})
            i += 1; continue
        if s.startswith("|") and i + 1 < n and re.match(r"^\s*\|?\s*:?-{2,}", lines[i + 1]):
            j, rows = i + 2, []
            while j < n and lines[j].strip().startswith("|"):
                rows.append(split_row(lines[j])); j += 1
            hdr = split_row(ln)
            rows = [(r + [""] * len(hdr))[:len(hdr)] for r in rows]
            blocks.append({"t": "table", "header": hdr, "rows": rows, "line": base + i})
            i = j; continue
        m = LIST_RE.match(ln)
        if m and len(m.group(1)) < 4:
            items, ordered, j = [], m.group(2)[0].isdigit(), i
            while j < n:
                mm = LIST_RE.match(lines[j])
                if mm:
                    items.append(mm.group(3).strip()); j += 1
                elif lines[j].strip() and lines[j].startswith((" ", "\t")) and items:
                    items[-1] += " " + lines[j].strip(); j += 1
                elif not lines[j].strip() and j + 1 < n and (LIST_RE.match(lines[j + 1]) or
                                                               (lines[j + 1].startswith("  ") and lines[j + 1].strip())):
                    j += 1
                else:
                    break
            blocks.append({"t": "list", "ordered": ordered, "items": items, "line": base + i})
            i = j; continue
        if s.startswith(">"):
            j, body = i, []
            while j < n and lines[j].strip().startswith(">"):
                body.append(re.sub(r"^\s*>\s?", "", lines[j]).strip()); j += 1
            blocks.append({"t": "quote", "text": " ".join(body), "line": base + i})
            i = j; continue
        j, body = i, []
        while j < n and lines[j].strip() and not lines[j].strip().startswith(("```", "<!--", "|", ">")) \
                and not re.match(r"^#{1,6} ", lines[j]) and not (j > i and LIST_RE.match(lines[j]) and len(LIST_RE.match(lines[j]).group(1)) < 4):
            body.append(lines[j].strip()); j += 1
        if j == i:          # a lone "|" line or similar: take it as text
            body.append(s); j = i + 1
        blocks.append({"t": "para", "text": " ".join(body), "line": base + i})
        i = j
    return blocks


def parse_script(path):
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    # section boundaries, ignoring "## main" lines inside fences
    cuts, fence = [], False
    for i, ln in enumerate(lines):
        if ln.strip().startswith("```"): fence = not fence
        elif not fence and SECTION_RE.match(ln): cuts.append(i)
    head = lines[:cuts[0]] if cuts else lines
    meta = {"title": "", "part": None, "part_name": "", "planned_minutes": None, "chapters": [], "header": {}}
    for ln in head:
        m = re.match(r"^# (V\d{3})[:.]?\s*(.*)$", ln)
        if m: meta["title"] = m.group(2).strip()
        m = re.match(r"^- \*\*([A-Za-z ]+?)[.:]\*\*[.:]?\s*(.*)$", ln)
        if m:
            key, val = m.group(1).strip().lower(), m.group(2).strip()
            meta["header"][key] = val
            if key == "part":
                pm = re.match(r"(\d+)\s*[:,.]?\s*(.*)", val)
                if pm: meta["part"], meta["part_name"] = int(pm.group(1)), pm.group(2).strip()
            elif key == "planned minutes":
                pm = re.search(r"\d+", val)
                if pm: meta["planned_minutes"] = int(pm.group(0))
            elif key.startswith("textbook"):
                meta["chapters"] = re.findall(r"textbook/(ch[0-9a-z-]+\.md)", val)
    sections = []
    for k, c in enumerate(cuts):
        end = cuts[k + 1] if k + 1 < len(cuts) else len(lines)
        sections.append({"name": SECTION_RE.match(lines[c]).group(1).strip(), "line": c + 1,
                         "blocks": parse_blocks(lines[c + 1:end], base=c + 2)})
    return meta, sections, text


# ---- textbook lookup -----------------------------------------------------------------------------
_TB_CACHE = {}
STOP = set("the a an of in on at to for and or with from by is are was be as it its this that these those one two three "
           "four five six seven eight nine ten each every row rows time section sections table diagram first second third "
           "then draw show shows shown beside above below again here there what which when how why not into than them "
           "you your can will all any both more most only same also".split())
KIND_WORDS = {
    "table": "table tables row rows column columns matrix grid",
    "diagram": "diagram diagrams drawing picture pictures figure sketch graph map ladder timeline lanes lane layout",
    "box": "box callout root-cause",
    "commands": "command commands",
    "transcript": "transcript output snippet",
    "list": "list questions question steps rules checklist items points",
}
ORDINALS = {"first": 0, "second": 1, "third": 2, "fourth": 3, "last": -1, "end": -1}
NUMWORDS = {w: i + 2 for i, w in enumerate("two three four five six seven eight nine ten eleven twelve".split())}


def wordset(s):
    return {w for w in re.findall(r"[a-z0-9][a-z0-9_.-]*[a-z0-9]|[a-z0-9]", plain(s).lower()) if w not in STOP and len(w) > 2}


def chapter_for(sec):
    m = re.match(r"(\d+)([A-D]?)\.", sec)
    hits = sorted(TEXTBOOK.glob(f"ch{int(m.group(1)):02d}{m.group(2).lower()}-*.md"))
    return hits[0] if hits else None


def textbook_section(sec):
    """-> (path, blocks) of textbook section 'N.M', or (None, [])."""
    path = chapter_for(sec)
    if not path:
        return None, []
    if path not in _TB_CACHE:
        _TB_CACHE[path] = path.read_text(encoding="utf-8").split("\n")
    lines = _TB_CACHE[path]
    start, end, fence = None, len(lines), False
    for i, ln in enumerate(lines):
        if ln.strip().startswith("```"): fence = not fence; continue
        if fence: continue
        if start is None:
            if re.match(rf"^##+ {re.escape(sec)}(?![\d.]*\d)\b", ln): start = i
        elif re.match(r"^#{1,2} ", ln):
            end = i; break
    if start is None:
        return path, []
    return path, parse_blocks(lines[start + 1:end], base=start + 2)


def resolve_textbook(direction, used):
    """Find the table / drawing / box a stage direction points at.  -> (visual dict, source dict) or (None, reason)."""
    secs = SECREF_RE.findall(direction)
    if not secs:
        return None, None
    dl = plain(direction).lower()
    dwords = wordset(SECREF_RE.sub(" ", direction))
    pos = {k: min([m.start() for w in ws.split() for m in [re.search(rf"\b{re.escape(w)}\b", dl)] if m] or [-1]) for k, ws in KIND_WORDS.items()}
    want = sorted([k for k in pos if pos[k] >= 0], key=lambda k: pos[k])
    nums = {NUMWORDS[w] for w in re.findall(r"[a-z]+", dl) if w in NUMWORDS} | {int(x) for x in re.findall(r"\b(\d{1,2})[- ](?:row|column|line)", dl)}
    ordinal = next((v for k, v in ORDINALS.items() if re.search(rf"\b{k}\b", dl)), None)
    reason = None
    for sec in secs:
        path, blocks = textbook_section(sec)
        if not blocks:
            reason = f"section {sec}: not found in the textbook"; continue
        cands = []
        for bi, b in enumerate(blocks):
            ctx = blocks[bi - 1]["text"] if bi and blocks[bi - 1]["t"] == "para" else ""
            if b["t"] == "table":
                kind, body, strong = "table", " ".join(sum(b["rows"], [])), " ".join(b["header"])
            elif b["t"] == "fence" and b["snippet"]:
                kind, body, strong = "transcript", b["text"], ""
            elif b["t"] == "fence" and b["lang"] in ("bash", "sh", "shell", "console"):
                kind, body, strong = "commands", b["text"], ""
            elif b["t"] == "fence" and re.search(r"(?mi)^\s*root cause\s*:", b["text"]):
                kind, body, strong = "box", b["text"], ""
            elif b["t"] == "fence":
                kind, body, strong = "diagram", b["text"], ""
            elif b["t"] == "quote":
                kind, body, strong = "box", b["text"], ""
            elif b["t"] == "list":
                kind, body, strong = "list", " ".join(b["items"]), ""
            else:
                continue
            score = len(dwords & wordset(body)) + 2 * len(dwords & wordset(strong)) + len(dwords & wordset(ctx))
            if b["t"] == "table" and nums and (len(b["rows"]) in nums or len(b["header"]) in nums): score += 2
            if b["t"] == "list" and nums and len(b["items"]) in nums: score += 2
            cands.append({"kind": kind, "block": b, "score": score})
        pools = [[c for c in cands if c["kind"] == k] for k in want]
        pools.append([c for c in cands if c["kind"] in ("table", "diagram", "box")])
        for pool in pools:
            if not pool:
                continue
            best = max(c["score"] for c in pool)
            top = [c for c in pool if c["score"] == best]
            pick = top[0]
            if len(top) > 1:
                if ordinal is not None:
                    pick = top[ordinal] if -len(top) <= ordinal < len(top) else top[0]
                else:                              # same score: prefer one this video has not shown yet
                    pick = next((c for c in top if (rel(path), c["block"]["line"]) not in used), top[0])
            b = pick["block"]
            src = {"file": rel(path), "line": b["line"], "section": sec, "kind": pick["kind"], "score": pick["score"],
                   "candidates": len(pool)}
            used.add((src["file"], src["line"]))
            return block_visual(b, pick["kind"]), src
        reason = f"section {sec}: no table, drawing or box found for {direction[:60]!r}"
    return None, reason


def text_table(text):
    """A table drawn in monospace (header, a row of dashes per column, rows) -> (header, rows) or None."""
    lines = [l.expandtabs(8).rstrip() for l in text.split("\n")]
    while lines and not lines[0].strip(): lines.pop(0)
    while lines and not lines[-1].strip(): lines.pop()
    if len(lines) < 3 or not re.fullmatch(r"\s*-{3,}(\s+-{3,})+", lines[1]):
        return None
    spans = [(m.start(), m.end()) for m in re.finditer(r"-{3,}", lines[1])]
    starts = [a for a, _ in spans]
    if len(starts) < 2 or len(starts) > 7:
        return None
    def cut(line):
        cells = []
        for k, a in enumerate(starts):
            e = starts[k + 1] if k + 1 < len(starts) else max(len(line), a)
            if k and a <= len(line) and line[a - 1:a].strip():       # text runs across a column boundary
                return None
            cells.append(line[a:e] if k else line[:e])
        return cells
    header = cut(lines[0])
    if header is None: return None
    rows, raw_first = [], [""]
    for ln in lines[2:]:
        if not ln.strip(): continue
        c = cut(ln)
        if c is None: return None
        first = c[0][starts[0]:] if len(c[0]) > starts[0] else c[0]
        open_end = bool(rows) and bool(c[0].strip()) and any(
            re.search(r"([,;:(]|\b(and|or|the|a|an|of|to|in|with|on|is|that|for|by|from|than|vs))$", x) for x in raw_first)
        if rows and (not c[0].strip() or first[:1] == " " or open_end):   # continuation line of the row above
            def join(x, y):
                y = y.strip()
                if not y: return x
                cmd = re.match(r"(git|gh|\$|\+|--|labs/)", y) or re.match(r"(git|gh|labs/) ", x)
                return (x + ("\u2028" if cmd and x else " ") + y).strip()
            rows[-1] = [join(x, y) for x, y in zip(rows[-1], c)]
            raw_first = [x.strip() for x in c]
        else:
            rows.append([x.strip() for x in c]); raw_first = [x.strip() for x in c]
    if not rows: return None
    esc = lambda x: x.replace("|", "\\|").replace("*", "\\*").replace("_", "\\_").replace("`", "'")
    return [esc(h.strip()) for h in header], [[esc(x) for x in r] for r in rows]


def block_visual(b, kind=None):
    if b["t"] == "table":
        return {"kind": "table", "header": b["header"], "rows": b["rows"]}
    if b["t"] == "fence" and not b["snippet"] and b["lang"] in ("text", ""):
        tt = text_table(b["text"])
        if tt: return {"kind": "table", "header": tt[0], "rows": tt[1], "mono": True}
    if b["t"] == "fence":
        if b["snippet"]:
            return {"kind": "terminal", "mode": "out", "title": b["snippet"], "text": b["text"]}
        if b["lang"] in ("bash", "sh", "shell", "console", "zsh"):
            return {"kind": "terminal", "mode": "cmd", "title": "", "text": b["text"]}
        if b["lang"] in ("yaml", "yml", "json", "toml", "ini", "python", "diff", "gitconfig", "gitignore", "gitattributes"):
            return {"kind": "terminal", "mode": "code", "title": b["lang"], "text": b["text"]}
        return {"kind": "diagram", "text": b["text"]}
    if b["t"] == "quote":
        m = re.match(r"\*\*(.+?)\*\*\s*(.*)", b["text"])
        return {"kind": "callout", "label": plain(m.group(1)).rstrip(".:") if m else "", "quotes": [m.group(2) if m else b["text"]],
                "code": [], "quoted": False}
    if b["t"] == "list":
        return {"kind": "bullets_static", "items": b["items"], "ordered": b["ordered"]}
    return None


# ---- stage directions ----------------------------------------------------------------------------
def quote_callout(direction):
    """A direction that quotes text -> callout visual, else None."""
    d = direction.strip()
    t = d.replace("“", '"').replace("”", '"')
    probe = CODE_RE.sub(lambda m: "\x01" * len(m.group(0)), t)     # ignore quotes inside code spans
    idx = [i for i, c in enumerate(probe) if c == '"']
    if len(idx) >= 2:
        inner = t[idx[0] + 1:idx[-1]]
        pieces = [p.strip() for p in re.split(r'"[\s,;.]*(?:and|or|then)?\s*"', inner)] if len(idx) % 2 == 0 and len(idx) >= 4 else [inner]
        # a nested quotation ("Explain "x" for y") is one piece, not three
        if len(pieces) > 1 and any(len(p.split()) < 3 for p in pieces):
            pieces = [inner]
        label = clean_label(t[:idx[0]].strip().rstrip(":").strip())
        tail = t[idx[-1] + 1:].strip(" .—-")
        return {"kind": "callout", "label": label, "quotes": [p for p in pieces if p], "code": [], "quoted": True,
                "tail": tail if len(tail.split()) <= 8 else ""}
    codes = [m.group(2).strip() for m in CODE_RE.finditer(d)]
    rest = CODE_RE.sub(" ", d)
    if codes and len(rest.split()) <= 14 and not SECREF_RE.search(d):
        m = re.match(r"^([^`]*?):\s*`", d)
        return {"kind": "callout", "label": clean_label(m.group(1).strip()) if m else "", "quotes": [], "code": codes, "quoted": False}
    return None


def is_bold_lead(md):
    m = re.match(r"^\*\*([^*]+?)\*\*[.:]?\s*(.*)$", md, re.S)
    if not m or len(m.group(1).split()) > 14:
        return None
    return m.group(1).strip().rstrip(".:"), m.group(2).strip()


def section_events(sec, used, warnings, last_scene, hints=None):
    """First pass over one section: visuals, narration and pauses in reading order."""
    ev, blocks = [], sec["blocks"]
    term_title = ""
    last_diagram = None
    scene_open = [False]
    narr_since_visual = 0
    twig = [None]                                    # the pose a "twig:" tag asked for: it goes to the next paragraph

    def nxt(i, k=1):
        j = i + 1
        while j < len(blocks) and blocks[j]["t"] == "para" and DIR_RE.match(blocks[j]["text"]) and \
                DIR_RE.match(blocks[j]["text"]).group(1) != "PAUSE" and k == 0:
            j += 1
        return blocks[j] if j < len(blocks) else None

    def silent_before(line):
        """A scene tag right after a picture nobody has read anything over: that picture is held in silence, then the scene takes the screen."""
        last = ev[-1] if ev else None
        if last and last["e"] == "visual" and last["v"]["kind"] in ("callout", "table") and narr_since_visual == 0:
            what = "on-screen text" if last["v"]["kind"] == "callout" else "table"
            # a hint, not a warning: the plan is what the script says (and what the videos of batch one show), but it is rarely what is meant
            (warnings if hints is None else hints).append(f"line {line}: the {what} of line {last['line']} is held in silence, because this [ANIMATION] scene tag takes the screen "
                                                          f"before a paragraph is read over it. Put the scene tag after the first paragraph, or remove the {what}")

    def pause(line):
        last = next((x for x in reversed(ev) if x["e"] in ("narr", "pause")), None)
        asked = bool(last and last["e"] == "narr" and PREDICT_RE.search(" ".join(sentences(last["text"])[-2:])))
        ev.append({"e": "pause", "line": line, "hold": HOLD_PREDICT if asked else HOLD_PAUSE})

    def add_narr(md, line):
        nonlocal narr_since_visual
        # inline [PAUSE] splits the paragraph
        parts = re.split(r"\s*\*\*\[PAUSE\]\*\*\s*", md)
        for pi, part in enumerate(parts):
            if pi: pause(line)
            if not part.strip(): continue
            for ci, chunk in enumerate(split_long(part)):
                ev.append({"e": "narr", "text": chunk, "md": part if ci == 0 else chunk, "line": line, "cont": ci > 0})
                if twig[0]: ev[-1]["twig"], twig[0] = twig[0], None
                narr_since_visual += 1

    i = 0
    while i < len(blocks):
        b = blocks[i]
        t = b["t"]
        if t == "para":
            m = DIR_RE.match(b["text"])
            if m:
                kind, rest = m.group(1), b["text"][m.end():].strip()
                if kind == "PAUSE":
                    pause(b["line"])
                    if rest: add_narr(rest, b["line"])
                    i += 1; continue
                if kind == "ANIMATION":
                    # a library scene (video/production/ANIMATION_STYLE.md lists the vocabulary), or the next step of the current one
                    tag = video_animplan.parse_tag(rest)
                    skip = 1
                    if tag is None:
                        warnings.append(f"line {b['line']}: [ANIMATION] tag not understood: {rest[:60]!r}")
                    else:
                        # a scene tag placed in front of a drawing replaces that drawing (the fence stays in the script for the book)
                        j = i + 1
                        if j < len(blocks) and blocks[j]["t"] == "para" and (DIR_RE.match(blocks[j]["text"]) or [None, None])[1] == "DIAGRAM": j += 1
                        if j < len(blocks) and blocks[j]["t"] == "fence" and not blocks[j]["snippet"] and blocks[j]["lang"] in ("text", ""):
                            skip = j - i + 1
                        named = lambda v, nm: nm in (v["scene"], str(v["params"].get("id", "")).lower()) or video_animplan.ALIASES.get(nm) == v["scene"]
                        drawing_next = skip > 1                  # the tag stands directly before a drawing ([DIAGRAM] and its fence, or a text fence)
                        if "end" in tag:                        # the scene leaves; what follows is read over key points again
                            ev.append({"e": "keymode", "badge": "", "line": b["line"], "direction": rest})
                            scene_open[0] = False; narr_since_visual = 0
                            skip = 1                            # "end" replaces nothing: a drawing after it is shown
                        elif "twig" in tag:                     # the mascot's pose for the next paragraph
                            twig[0] = tag["twig"]; skip = 1
                        elif "say" in tag or "replay" in tag:
                            # a new caption for the scene on screen, or the scene once more from its first step; a scene that left comes back
                            nm = tag.get("replay", "")
                            owner = next((v for v in reversed(last_scene) if not nm or named(v, nm)), None)
                            if owner is None:
                                warnings.append(f"line {b['line']}: [ANIMATION] {rest[:40]!r}: there is no scene before it" + (f" called {nm!r}" if nm else ""))
                            elif "replay" in tag:
                                if drawing_next:
                                    warnings.append(f"line {b['line']}: [ANIMATION] {rest[:40]!r} stands directly before a drawing: the scene plays in silence and the paragraphs "
                                                    "are read over the drawing. Put the replay tag after the drawing, or put a 'step:' tag before the drawing to replace it")
                                again = dict(owner, _st={"upto": 0, "shown": 0})
                                last_scene.append(again)
                                ev.append({"e": "visual", "v": again, "line": b["line"]}); scene_open[0] = True; narr_since_visual = 0
                            else:
                                if not (scene_open[0] and owner is last_scene[-1]):
                                    ev.append({"e": "visual", "v": owner, "line": b["line"], "held": True})    # the scene returns as it was: no step is played
                                    last_scene.remove(owner); last_scene.append(owner); scene_open[0] = True
                                ev.append({"e": "scene_say", "text": tag["say"], "line": b["line"]}); narr_since_visual = 0
                            skip = 1
                        elif "step" in tag:
                            # the step belongs to the most recent scene that has a step of that name ("step: rebase.copy", "step: <id>.copy" name the scene)
                            sname, _, step = tag["step"].rpartition(".")
                            owner = next((v for v in reversed(last_scene) if step in v["steps"] and (not sname or named(v, sname))), None)
                            if owner is None and sname:         # a step name may itself contain a dot
                                step = tag["step"]; owner = next((v for v in reversed(last_scene) if step in v["steps"]), None)
                            if owner is None:
                                warnings.append(f"line {b['line']}: [ANIMATION] step {tag['step']!r}: no scene before it has that step")
                            elif scene_open[0] and owner is last_scene[-1]:
                                ev.append({"e": "scene_step", "step": step, "line": b["line"]})
                                narr_since_visual = 0           # the scene stays: a bold lead-in right after this tag is read over it
                            else:                               # that scene left the screen meanwhile: bring it back where it stopped
                                ev.append({"e": "visual", "v": owner, "line": b["line"]})
                                ev.append({"e": "scene_step", "step": step, "line": b["line"]})
                                last_scene.remove(owner); last_scene.append(owner)
                                scene_open[0] = True; narr_since_visual = 0
                        else:
                            steps = video_animplan.scene_steps(tag["scene"], tag["params"])
                            if tag.get("only"): steps = list(tag["only"])
                            elif tag.get("last"): steps = steps[:steps.index(tag["last"]) + 1]
                            vis = {"kind": "scene", "scene": tag["scene"], "params": tag["params"], "steps": steps, "direction": rest, "_st": {"upto": 0, "shown": 0}}
                            silent_before(b["line"])
                            last_scene.append(vis)
                            ev.append({"e": "visual", "v": vis, "line": b["line"]}); narr_since_visual = 0
                            scene_open[0] = True
                    i += skip; continue
                if kind == "TERMINAL":
                    cm = re.search(r"`((?:labs/|\$LAB)[^`]+)`", rest)
                    if cm: term_title = cm.group(1)
                n1 = blocks[i + 1] if i + 1 < len(blocks) else None
                n2 = blocks[i + 2] if i + 2 < len(blocks) else None
                concrete_next = n1 is not None and (n1["t"] in ("fence", "table", "list") or
                                                    (n1["t"] == "para" and n1["text"].rstrip().endswith(":") and n2 is not None and n2["t"] == "list"))
                if concrete_next or not rest:
                    if n1 is not None and n1["t"] == "fence": n1["note"] = rest
                    i += 1; continue
                vis, src = resolve_textbook(rest, used)
                if vis is None and src:
                    warnings.append(f"line {b['line']}: {src}")
                if vis is None:
                    vis = quote_callout(rest)
                    if vis is not None and kind == "TERMINAL" and not vis.get("quoted"): vis = None
                    src = None
                cm2 = re.match(r"(?:Callout|(?:The )?State table|Rule|Definition|Version note)\s*:\s*(.+)$", rest, re.I | re.S)
                if vis is None and cm2:
                    vis = {"kind": "callout", "label": clean_label(rest.split(":")[0].strip()) if not rest.lower().startswith("callout") else "",
                           "quotes": [cm2.group(1).strip()], "code": [], "quoted": False}
                run = re.search(r"`(labs/run [^`]+)`", rest)
                if vis is None and run:
                    vis = {"kind": "terminal", "mode": "cmd", "title": term_title, "text": run.group(1)}
                if vis is None and kind == "DIAGRAM" and last_diagram is not None:
                    vis = dict(last_diagram)            # "point at the two arrows": bring the drawing back
                scene_open[0] = False
                if vis is not None:
                    vis["direction"] = rest
                    if src: vis["source"] = src
                    if vis["kind"] == "diagram": last_diagram = {k: v for k, v in vis.items() if k != "direction"}
                    ev.append({"e": "visual", "v": vis, "line": b["line"]}); narr_since_visual = 0
                else:
                    bm = re.match(r"(?:Lower[- ]third|Layer label|Label)\s*:\s*([^.]{1,40})", plain(rest), re.I)
                    ev.append({"e": "keymode", "badge": bm.group(1).strip() if bm else "",
                               "line": b["line"], "direction": rest})
                    narr_since_visual = 0
                i += 1; continue
            # narration paragraph
            lead = is_bold_lead(b["text"])
            n1 = blocks[i + 1] if i + 1 < len(blocks) else None
            if b["text"].rstrip().endswith(":") and n1 is not None and n1["t"] == "list" and words(b["text"]) <= 40:
                ev.append({"e": "bullets", "items": n1["items"], "ordered": n1["ordered"], "lead": b["text"],
                           "line": n1["line"], "lead_line": b["line"]})
                narr_since_visual = 0; scene_open[0] = False
                i += 2; continue
            qm = re.match(r'^\**(Q\d+)[:.]?\**[:.]?\s*["“](.+)["”]\s*$', b["text"], re.S)
            if qm:
                ev.append({"e": "visual", "v": {"kind": "callout", "label": qm.group(1), "quotes": [qm.group(2)], "code": [], "quoted": True},
                           "line": b["line"]})
                narr_since_visual = 0; scene_open[0] = False
            if lead:
                # a bold lead-in starts a new topic; it replaces a visual that has already been talked over
                ev.append({"e": "topic", "headline": lead[0], "switch": narr_since_visual > 0, "line": b["line"]})
                if narr_since_visual > 0: scene_open[0] = False
            add_narr(b["text"], b["line"])
            i += 1; continue
        if t == "list":
            ev.append({"e": "bullets", "items": b["items"], "ordered": b["ordered"], "lead": None, "line": b["line"]})
            narr_since_visual = 0; scene_open[0] = False
        elif t in ("fence", "table", "quote"):
            vis = block_visual(b)
            if vis["kind"] == "terminal":
                if vis["mode"] == "cmd": vis["title"] = term_title
                elif vis["mode"] == "out" and not vis["title"]: vis["title"] = term_title
            if vis["kind"] == "diagram": last_diagram = dict(vis)
            if b.get("note"): vis["direction"] = b["note"]
            ev.append({"e": "visual", "v": vis, "line": b["line"]}); narr_since_visual = 0; scene_open[0] = False
        i += 1
    return ev


# ---- pagination ------------------------------------------------------------------------------------
def term_lines(text, mode):
    out = []
    cont = False
    for raw in text.split("\n"):
        s = raw.expandtabs(8).rstrip()
        if mode == "out":
            if s.startswith("$ "): out.append({"t": "cmd", "s": s[2:]})
            elif s == "$": out.append({"t": "cmd", "s": ""})
            elif re.match(r"^\[exit status: \d+\]$", s): out.append({"t": "exit", "s": s})
            else: out.append({"t": "out", "s": s})
        elif mode == "cmd":
            if not s.strip(): out.append({"t": "out", "s": ""})
            elif s.lstrip().startswith("#"): out.append({"t": "cmt", "s": s})
            elif cont: out.append({"t": "more", "s": s})
            else: out.append({"t": "cmd", "s": s})
            cont = s.endswith("\\") and not s.lstrip().startswith("#")
        else:
            out.append({"t": "code", "s": s})
    while out and not out[-1]["s"] and out[-1]["t"] != "cmd": out.pop()
    return out


def paginate_terminal(text, mode, avail_h):
    """-> (font size, pages).  Text is never drawn below 26 px: long lines wrap and long output is split in pages."""
    lines = term_lines(text, mode)
    inner_w = CONTENT_W - TERM_PAD_W
    def width(l): return len(l["s"]) + (2 if l["t"] in ("cmd", "more") else 0)
    longest = max([width(l) for l in lines] or [1])
    def cap(fs): return int(inner_w / (MONO_ADV * fs)), int((avail_h - TERM_CHROME_H) / (fs * TERM_LH))
    fs = TERM_FS[-1]
    for f in TERM_FS:
        cols, rows = cap(f)
        if longest <= cols and len(lines) <= rows:
            fs = f; break
    else:
        # does not fit on one page at any size: prefer the largest size at which no line wraps and at most 2 pages are needed
        for f in TERM_FS:
            cols, rows = cap(f)
            if longest <= cols and len(lines) <= 2 * rows and f <= 30:
                fs = f; break
    cols, rows = cap(fs)
    wrapped = []
    for l in lines:
        pre = 2 if l["t"] in ("cmd", "more") else 0
        s = l["s"]
        if len(s) + pre <= cols:
            wrapped.append(l); continue
        first = True
        while s:
            room = cols - pre if first else cols - 4
            cut = room
            if len(s) > room:
                k = s.rfind(" ", int(room * 0.6), room + 1)
                if k > 0: cut = k
            wrapped.append({"t": l["t"] if first else "wrap", "s": s[:cut], **({"of": l["t"]} if not first else {})})
            s = s[cut:].lstrip(" ") if len(s) > cut else ""
            first = False
    if len(wrapped) <= rows:
        return fs, [wrapped]
    pages, cur, last_cmd = [], [], None
    i = 0
    # aim for pages of equal length (no page with one orphan line); "rows" stays the hard limit
    npages = math.ceil(len(wrapped) / rows)
    npages = math.ceil((len(wrapped) + 2 * (npages - 1)) / rows)
    soft = min(rows, math.ceil((len(wrapped) + 2 * (npages - 1)) / npages) + 1)
    while i < len(wrapped):
        room = soft - len(cur)
        rest = len(wrapped) - i
        if rest <= rows - len(cur) and len(pages) == npages - 1:
            room = rows - len(cur)                 # the last page takes whatever is left
        if room <= 0 or (wrapped[i]["t"] == "cmd" and cur and len(cur) >= soft * 0.5 and len(pages) < npages - 1 and
                         next((k for k in range(i + 1, len(wrapped)) if wrapped[k]["t"] == "cmd"), len(wrapped)) - i > room):
            pages.append(cur); cur = []
            if wrapped[i]["t"] != "cmd" and last_cmd is not None:
                cur.append({"t": "ctx", "s": last_cmd}); cur.append({"t": "ctx2", "s": "…"})
            continue
        if wrapped[i]["t"] == "cmd": last_cmd = wrapped[i]["s"]
        cur.append(wrapped[i]); i += 1
    if cur: pages.append(cur)
    if len(pages) >= 2:
        # no orphan page: a last page of a few lines takes some lines from the page before it
        tail = [l for l in pages[-1] if l["t"] not in ("ctx", "ctx2")]
        head = [l for l in pages[-1] if l["t"] in ("ctx", "ctx2")]
        prev = pages[-2]
        if len(tail) <= 5 and len(prev) > 10:
            if len(prev) + len(tail) <= rows:
                pages[-2:] = [prev + tail]
            else:
                k = min(len(prev) // 3, 7)
                moved = prev[-k:]
                if moved[0]["t"] == "cmd" or not head:
                    ctx_cmd = next((l["s"] for l in reversed(prev[:-k]) if l["t"] in ("cmd", "ctx")), None)
                    head = [] if moved[0]["t"] == "cmd" or ctx_cmd is None else [{"t": "ctx", "s": ctx_cmd}, {"t": "ctx2", "s": "…"}]
                pages[-2], pages[-1] = prev[:-k], head + moved + tail
    return fs, pages


def _tokens(md):
    """Lengths of the unbreakable pieces of a cell (short code spans do not wrap)."""
    t, keep = _stash_code(md)
    out = []
    for w in _strip_marks(t).split():
        m = re.fullmatch(r"(.*)\x02(\d+)\x03(.*)", w)
        if m:
            c = keep[int(m.group(2))]
            out.append(len(m.group(1)) + len(m.group(3)) + (len(c) if len(c) <= 30 else max(len(x) for x in c.split() or [""])) + 1)
        else:
            out.append(len(w))
    return out or [1]


def table_layout(header, rows, fs, mono=False):
    """Column widths (in characters) and row heights (px) for a table drawn at font size fs with fixed columns."""
    ncol = max(1, len(header))
    cw = 0.56 if mono else 0.5                      # average character width in em
    lens = [[len(plain(c)) + 1 for c in r] for r in rows]
    hl = [int((len(plain(c)) + 1) * 0.74 * 1.3) for c in header]      # header: smaller, upper case, letter-spaced
    nat = [max([hl[k]] + [l[k] for l in lens]) for k in range(ncol)]
    minw = [max([int(max(_tokens(c)) * 1.15) + 2 for c in [r[k] for r in rows]] + [int(max(_tokens(header[k])) * 0.74 * 1.4) + 2]) for k in range(ncol)]
    total = (CONTENT_W / fs - 1.2 * ncol) / cw
    raw_min = [max([max(_tokens(c)) + 1 for c in [r[k] for r in rows]] + [int(max(_tokens(header[k])) * 0.74 * 1.3) + 1]) for k in range(ncol)]
    if sum(nat) <= total:
        w = [n + (total - sum(nat)) * n / sum(nat) for n in nat]
    else:
        w = [float(min(m, nat[k])) for k, m in enumerate(minw)]
        if sum(w) > total:
            w = [x * total / sum(w) for x in w]
        left = total - sum(w)
        def height(ws): return sum(max(math.ceil(l[k] / max(ws[k], 3)) for k in range(ncol)) for l in lens)
        while left >= 1:
            # widen the column where one more character makes the table shortest
            best, key = None, None
            for k in range(ncol):
                if w[k] >= nat[k]: continue
                w[k] += 1
                cand = (height(w), -sum(l[k] for l in lens) / (w[k] * w[k]))
                w[k] -= 1
                if key is None or cand < key: best, key = k, cand
            if best is None: break
            w[best] += 1; left -= 1
        if left > 0:
            w = [x + left * x / sum(w) for x in w]
    lh = fs * 1.3
    def rh(ls, scale=1.0): return max(math.ceil(l / max(w[k], 3)) for k, l in enumerate(ls)) * lh * scale + fs * 0.9
    frac = [(x * cw + 1.2) for x in w]
    lines = sum(max(math.ceil(l[k] / max(w[k], 3)) for k in range(ncol)) for l in lens)
    return [round(100 * f / sum(frac), 2) for f in frac], rh(hl, 0.74) + 8, [rh(l) for l in lens], sum(raw_min) > total * 0.93, lines


def paginate_table(header, rows, avail_h, mono=False):
    """-> (font size, column widths in %, pages as lists of row indexes).  Rows are split over pages rather than shrunk."""
    avail = avail_h * 0.97 - 34                   # room for the page marker
    def pack(fs):
        cols, hh, rhs, cramped, nlines = table_layout(header, rows, fs, mono)
        pages, cur, used = [], [], 0.0
        for k, h in enumerate(rhs):
            if cur and used + h > avail - hh:
                pages.append(cur); cur, used = [], 0.0
            cur.append(k); used += h
        if cur: pages.append(cur)
        return cols, hh, rhs, pages, cramped, nlines
    small = pack(TABLE_FS[-1])
    fewest = len(small[3])
    for fs in TABLE_FS:
        # the largest type that needs no more pages, breaks no words and does not wrap much more than the smallest type
        cols, hh, rhs, pages, cramped, nlines = pack(fs)
        if len(pages) <= fewest and (not cramped or fs == TABLE_FS[-1]) and nlines <= max(small[5] * 1.3, small[5] + 2):
            break
    if len(pages) > 1:                             # even out the pages
        target = sum(rhs) / len(pages)
        bal, cur, used = [], [], 0.0
        for k, h in enumerate(rhs):
            if cur and (used + h > avail - hh or (used + h / 2 >= target and len(bal) < len(pages) - 1)):
                bal.append(cur); cur, used = [], 0.0
            cur.append(k); used += h
        if cur: bal.append(cur)
        if len(bal) == len(pages): pages = bal
    return fs, cols, pages, cramped


CARD_FS = 34


def paginate_cards(header, rows, avail_h):
    """A table too wide for the frame is shown one row at a time: the first cell as a heading, the others as labelled lines."""
    fs = CARD_FS
    label_w = min(0.30, max(0.14, (max(len(plain(h)) for h in header[1:] or [""]) * 0.74 * 1.3 * 0.56 * fs + 40) / CONTENT_W))
    cpl = (CONTENT_W * (1 - label_w) - 80) / (fs * 0.5)
    def h(r):
        lines = sum(max(1, math.ceil((len(plain(c)) + 1) / cpl)) for c in r[1:])
        return fs * 1.25 * 1.3 + lines * fs * 1.3 + (len(r) - 1) * fs * 0.42 + fs * 1.9
    pages, cur, used = [], [], 0.0
    for k, r in enumerate(rows):
        if cur and used + h(r) > avail_h * 0.97 - 34:
            pages.append(cur); cur, used = [], 0.0
        cur.append(k); used += h(r)
    if cur: pages.append(cur)
    return fs, round(label_w * 100, 1), pages


def paginate_bullets(items, lead, avail_h):
    def run(fs):
        cpl = (CONTENT_W - 2.2 * fs) / (fs * 0.50)
        lh = fs * 1.3
        lead_h = (math.ceil(len(plain(lead)) / cpl) * lh + fs * 0.9) if lead else 0
        hs = [math.ceil((len(plain(it)) + 1) / cpl) * lh + fs * 0.62 for it in items]
        return lead_h, hs
    for fs in BULLET_FS:
        lead_h, hs = run(fs)
        if lead_h + sum(hs) <= avail_h:
            return fs, [list(range(len(items)))]
    fs = BULLET_FS[-1]
    lead_h, hs = run(fs)
    room = avail_h - lead_h
    npages = math.ceil(sum(hs) / room)
    while True:
        target = sum(hs) / npages
        pages, cur, used = [], [], 0.0
        for k, h in enumerate(hs):
            if cur and (used + h > room or (used >= target * 0.95 and len(pages) < npages - 1)):
                pages.append(cur); cur, used = [], 0.0
            cur.append(k); used += h
        if cur: pages.append(cur)
        if len(pages) <= npages or npages > len(items): return fs, pages
        npages += 1


# ---- second pass: beats and slides ---------------------------------------------------------------------
class Board:
    def __init__(self, vid, meta):
        self.vid, self.meta = vid, meta
        self.slides, self.beats, self.index = [], [], {}
        self.section = ""
        self.twigs = {}                                  # (line, text) of a paragraph -> the mascot pose a "twig:" tag asked for

    def slide(self, payload):
        p = {k: v for k, v in payload.items() if v not in (None, "", [])}
        p["section"] = self.section
        key = json.dumps({k: v for k, v in p.items() if k != "direction"}, sort_keys=True, ensure_ascii=False)
        if key not in self.index:
            p2 = dict(p); p2["n"] = len(self.slides) + 1
            self.slides.append(p2); self.index[key] = p2["n"]
        return self.index[key]

    def hold(self, slide, seconds, why, line=None):
        self.beats.append({"i": len(self.beats), "section": self.section, "type": "hold", "why": why, "hold": seconds,
                           "text": "", "tele": "", "words": 0, "est": seconds, "slide": slide, "line": line})

    def narr(self, slide, text, line=None):
        n = words(text)
        self.beats.append({"i": len(self.beats), "section": self.section, "type": "narration", "text": plain(text),
                           "tele": text, "words": n, "est": est_seconds(n), "slide": slide, "line": line})
        pose = self.twigs.pop((line, text), None)
        if pose: self.beats[-1]["twig"] = pose


def match_row(text, header, rows):
    """Which table row is this paragraph about?  -> row index or -1."""
    p = " " + re.sub(r"[^a-z0-9<>./_-]+", " ", plain(text).lower()) + " "
    head = " " + " ".join(p.split()[:8]) + " "
    hits = []
    for k, r in enumerate(rows):
        cell = re.sub(r"[^a-z0-9<>./_-]+", " ", plain(r[0]).lower()).strip() if r else ""
        if not cell or len(cell) > 40: continue
        probe = f" {cell} "
        if re.fullmatch(r"\d{1,2}", cell):
            probe = f" step {cell} " if f" step {cell} " in head else f" {cell} "
            if head.strip().split()[:1] != [cell] and f" step {cell} " not in head: continue
        if probe in p:
            hits.append((k, head.find(probe), len(cell)))
    if not hits or len(hits) >= 3: return -1
    hits = [h for h in hits if h[1] >= 0]
    if not hits: return -1
    hits.sort(key=lambda h: (h[1], -h[2]))
    return hits[0][0]


def match_page(text, pages):
    """Which page of a long terminal transcript is this paragraph about?  -> page index or None."""
    codes = [m.group(2).strip() for m in CODE_RE.finditer(text) if len(m.group(2).strip()) >= 3]
    if not codes: return None
    scores = []
    for pg in pages:
        cmds = "\n".join(l["s"] for l in pg if l["t"] in ("cmd",))
        body = "\n".join(l["s"] for l in pg)
        scores.append(sum(3 if c in cmds else (1 if c in body else 0) for c in codes))
    best = max(scores)
    return scores.index(best) if best > 0 and scores.count(best) == 1 else None


def assign_pages(matches, npages):
    """Per-beat page (None = no match) -> monotone-ish assignment that ends on the last page."""
    m = len(matches)
    out = list(matches)
    free = [i for i, x in enumerate(out) if x is None]
    for i in free:
        prev = next((out[j] for j in range(i - 1, -1, -1) if out[j] is not None), None)
        nxt = next((out[j] for j in range(i + 1, m) if out[j] is not None), None)
        guess = max(0, min(npages - 1, int((i + 1) * npages / m) - 1 if m else 0))
        lo = prev if prev is not None else 0
        hi = nxt if nxt is not None else npages - 1
        out[i] = min(max(guess, lo), max(lo, hi))
    return out


def run_visual(bd, vis, items, captions_ok=True, held=False):
    """Lay one concrete visual over the narration and pause events that follow it."""
    narr = [x for x in items if x["e"] == "narr"]
    total = sum(est_seconds(words(x["text"])) for x in narr)
    kind = vis["kind"]
    cap = captions_ok and total > LONG_RUN and len(narr) >= 2 and kind != "scene"
    avail = CONTENT_H - (CAPTION_H if cap else 0)
    base = {"kind": kind}
    if vis.get("source"): base["source"] = vis["source"]
    if vis.get("direction"): base["direction"] = vis["direction"]
    pages = [None]
    if kind == "terminal":
        fs, pages = paginate_terminal(vis["text"], vis["mode"], avail)
        base.update({"mode": vis["mode"], "title": vis.get("title", ""), "fs": fs})
    elif kind == "table":
        fs, cols, pages, cramped = paginate_table(vis["header"], vis["rows"], avail, vis.get("mono", False))
        base.update({"header": [inline_html(c) for c in vis["header"]], "fs": fs, "cols": cols, "mono": vis.get("mono", False)})
        if cramped and len(vis["header"]) >= 4:
            fs, label_w, pages = paginate_cards(vis["header"], vis["rows"], avail)
            base.update({"fs": fs, "layout": "cards", "label_w": label_w}); base.pop("cols")
    elif kind == "diagram":
        base.update({"text": vis["text"]})
        graph = video_animplan.parse_graph(vis["text"])      # an ASCII commit graph is replayed as an animated scene
        if graph: base["graph"] = graph
    elif kind == "scene":
        return run_scene(bd, vis, items, base, held)
    elif kind == "callout":
        base.update({"label": inline_html(vis.get("label", "")), "quotes": [inline_html(q) for q in vis.get("quotes", [])],
                     "code": vis.get("code", []), "quoted": vis.get("quoted", False), "tail": inline_html(vis.get("tail", ""))})
    elif kind == "bullets_static":
        fs, pages = paginate_bullets(vis["items"], None, avail - 40)
        base.update({"kind": "bullets", "ordered": vis["ordered"], "fs": fs})
    np_ = len(pages)

    def make(page, text=None, hl=-1):
        p = dict(base)
        if kind == "terminal":
            p["lines"] = pages[page]
        elif kind == "bullets_static":
            p["items"] = [inline_html(vis["items"][k]) for k in pages[page]]
            p["start"], p["shown"] = pages[page][0] + 1, len(pages[page])
            if hl in pages[page]: p["current"] = pages[page].index(hl)
        elif kind == "table":
            p["rows"] = [[inline_html(c) for c in vis["rows"][k]] for k in pages[page]]
            if hl in pages[page]: p["hl"] = pages[page].index(hl)
        if np_ > 1: p["page"] = [page + 1, np_]
        if cap and text: p["caption"] = inline_html(first_sentence(text, 170))
        return bd.slide(p)

    # page / row for every narration beat
    if kind == "table":
        rows_hit = [match_row(x["text"], vis["header"], vis["rows"]) for x in narr]
        matches = [next((pi for pi, pg in enumerate(pages) if r in pg), None) if r >= 0 else None for r in rows_hit]
    elif kind == "bullets_static":
        leads = [[(is_bold_lead(it) or (" ".join(plain(it).split()[:3]), ""))[0]] for it in vis["items"]]
        rows_hit = [match_row(x["text"], ["item"], leads) for x in narr]
        matches = [next((pi for pi, pg in enumerate(pages) if r in pg), None) if r >= 0 else None for r in rows_hit]
    elif kind == "terminal" and np_ > 1:
        rows_hit = [-1] * len(narr)
        matches = [match_page(x["text"], pages) for x in narr]
    else:
        rows_hit, matches = [-1] * len(narr), [0] * len(narr)
    if kind in ("table", "bullets_static") and np_ > 1 and matches:
        # once a row has been named, stay on its page until another row is named
        for k in range(1, len(matches)):
            if matches[k] is None and matches[k - 1] is not None and any(m is not None for m in matches[k:]): matches[k] = matches[k - 1]
    assigned = assign_pages(matches, np_) if narr else []
    seen = set(assigned)
    k = 0
    cur_page = 0
    last_slide = None
    shown_holds = set()

    def holds_before(page):
        nonlocal last_slide
        for q in range(np_):
            if q < page and q not in seen and q not in shown_holds:
                shown_holds.add(q)
                last_slide = make(q)
                bd.hold(last_slide, HOLD_PAGE, "page")

    for x in items:
        if x["e"] == "narr":
            pg = assigned[k]
            holds_before(pg)
            last_slide = make(pg, x["text"], rows_hit[k])
            bd.narr(last_slide, x["text"], x["line"])
            cur_page = pg; k += 1
        elif x["e"] == "pause":
            if last_slide is None:
                last_slide = make(0)
            bd.hold(last_slide, x.get("hold", HOLD_PAUSE), "pause", x["line"])
    if not narr:
        if last_slide is None or np_ > 1:
            # nothing is read over this visual: hold it long enough to be taken in
            size = len(vis.get("text", "").split("\n")) if kind in ("diagram", "terminal") else len(vis.get("rows", [])) * 2
            hold = HOLD_VISUAL if kind not in ("diagram", "table") else round(min(12.0, max(HOLD_VISUAL, 4 + 0.35 * size)), 1)
            if kind == "terminal":
                hold = round(min(5.0, 2.0 + 0.5 * size), 1) if vis["mode"] == "cmd" else round(min(8.0, 3 + 0.25 * size), 1)
            for q in range(np_):
                sl = make(q)
                if np_ == 1 and bd.beats and bd.beats[-1]["slide"] == sl:
                    continue                      # the same drawing brought back with nothing new to say
                bd.hold(sl, hold if np_ == 1 else max(HOLD_PAGE, hold / np_), "visual")
    else:
        holds_before(np_)
    return base


def run_scene(bd, vis, items, base, held=False):
    """A library scene: its steps are spread over the beats read under it, or follow explicit '[ANIMATION] step: name' tags.
    The scene remembers how far it got, so a later 'step:' tag can bring it back and go on."""
    steps = vis["steps"]
    S = len(steps)
    danger = video_animplan.danger_steps(vis["scene"], vis["params"])
    state = vis["_st"]
    start = state["shown"]                               # > 0 when the scene comes back
    base.update({"scene": vis["scene"], "params": vis["params"], "steps": steps})
    if start: base["base"] = start
    if start and state.get("says"): base["says_before"] = list(state["says"])
    dirty = [False]                                      # a "say:" tag changed the caption and nothing was shown since
    narr = [x for x in items if x["e"] == "narr"]
    explicit = any(x["e"] == "scene_step" for x in items) or (held and start > 0)     # brought back by "say:": only "step:" tags advance it

    def make():
        p = dict(base)
        p["upto"] = max(1, state["upto"])
        if any(s in danger for s in steps[state["shown"]:p["upto"]]): p["danger"] = True
        state["shown"] = p["upto"]
        if state.get("says"): p["says"] = list(state["says"])
        dirty[0] = False
        return bd.slide(p)

    def advance(to):
        if to > state["upto"]: state["upto"] = to; state["says"] = []      # a new step brings its own caption

    plan = video_animplan.spread_steps(vis["scene"], steps, start, [x["text"] for x in narr]) if narr and not explicit else []
    k, last = 0, None
    for x in items:
        if x["e"] == "scene_step":
            if x["step"] in steps: advance(steps.index(x["step"]) + 1)
        elif x["e"] == "scene_say":
            state.setdefault("says", []).append(x["text"]); dirty[0] = True
        elif x["e"] == "narr":
            if not explicit: advance(plan[k])
            k += 1
            last = make()
            bd.narr(last, x["text"], x["line"])
        elif x["e"] == "pause":
            bd.hold(last or make(), x.get("hold", HOLD_PAUSE), "pause", x["line"])
    if not narr:
        if not explicit: state["upto"] = S
        n = max(1, state["upto"] - start)
        bd.hold(make(), round(1.5 + n * video_animplan.STEP_SECONDS, 1), "visual")
    elif state["upto"] > state["shown"] or dirty[0]:     # a step tag (or a new caption) after the last paragraph
        bd.hold(make(), video_animplan.STEP_SECONDS, "visual")
    return base


def run_bullets(bd, ev, items):
    """A list: the lead-in line, then one beat per bullet (or the whole list in one beat), then what follows."""
    its = ev["items"]
    avg = sum(words(x) for x in its) / max(1, len(its))
    separate = avg >= 6
    trailing = [x for x in items if x["e"] == "narr"]
    total = sum(est_seconds(words(x["text"])) for x in trailing)
    cap = total > LONG_RUN and len(trailing) >= 2
    fs, pages = paginate_bullets(its, ev.get("lead"), CONTENT_H - (CAPTION_H if cap else 0))
    lead_html = inline_html(ev["lead"]) if ev.get("lead") else ""
    hit = [x for x in its]

    def make(page, shown, current=None, caption=None):
        p = {"kind": "bullets", "lead": lead_html, "items": [inline_html(its[k]) for k in pages[page]], "ordered": ev["ordered"],
             "start": pages[page][0] + 1, "shown": shown, "fs": fs}
        if current is not None: p["current"] = current
        if len(pages) > 1: p["page"] = [page + 1, len(pages)]
        if caption: p["caption"] = caption
        return bd.slide(p)

    if ev.get("lead"):
        bd.narr(make(0, 0 if separate else len(pages[0])), tele(ev["lead"]), ev.get("lead_line"))
    last = None
    for pi, pg in enumerate(pages):
        if separate:
            for j, k in enumerate(pg):
                chunks = split_long(its[k])
                for c in chunks:
                    last = make(pi, j + 1, j)
                    bd.narr(last, c, ev["line"])
        else:
            last = make(pi, len(pg))
            bd.narr(last, " ".join(tele(its[k]).rstrip(".;") + "." for k in pg), ev["line"])
    for x in items:
        if x["e"] == "narr":
            last = make(len(pages) - 1, len(pages[-1]), None, inline_html(first_sentence(x["text"], 170)) if cap else None)
            bd.narr(last, x["text"], x["line"])
        elif x["e"] == "pause":
            bd.hold(last or make(len(pages) - 1, len(pages[-1])), x.get("hold", HOLD_PAUSE), "pause", x["line"])


def build(vid):
    path = script_path(vid)
    if not path:
        raise SystemExit(f"{vid}: no script in video/scripts/")
    meta, sections, text = parse_script(path)
    warnings, hints = [], []                         # hints: the plan is valid but probably not what was meant (printed like warnings)
    if meta["part"] is None or meta["part"] not in PARTS:
        warnings.append("header has no usable Part line; palette of part 0 used")
    part = meta["part"] if meta["part"] in PARTS else 0
    bd = Board(vid, meta)
    used = set()
    last_scene = []                                  # the scenes shown so far: "[ANIMATION] step: x" can bring one back
    bd.section = "TITLE"
    bd.hold(bd.slide({"kind": "title", "title": meta["title"], "part_name": meta["part_name"]}), HOLD_TITLE, "title")
    sec_index = []
    for si, sec in enumerate(sections):
        bd.section = sec["name"]
        sec_index.append({"name": sec["name"], "beat": len(bd.beats), "line": sec["line"]})
        bd.hold(bd.slide({"kind": "section", "name": sec["name"], "index": si + 1, "count": len(sections)}), HOLD_SECTION, "section", sec["line"])
        events = section_events(sec, used, warnings, last_scene, hints)
        bd.twigs.update({(e["line"], e["text"]): e["twig"] for e in events if e.get("twig")})
        # group: a visual (or key-point mode) and the narration under it
        topic, badge = "", ""
        i = 0
        mode = ("key", None)
        group = []

        def flush():
            nonlocal group
            if mode[0] == "key":
                last = None
                for x in group:
                    if x["e"] == "narr":
                        lead = is_bold_lead(x["md"]) if not x.get("cont") else None
                        body = first_sentence(lead[1] if lead else x["text"]) if (not lead or lead[1]) else ""
                        last = bd.slide({"kind": "keypoint", "headline": inline_html(x.get("topic") or ""), "body": inline_html(body),
                                         "badge": x.get("badge", "")})
                        bd.narr(last, x["text"], x["line"])
                    elif x["e"] == "pause":
                        if last is None:
                            last = bd.beats[-1]["slide"]
                        bd.hold(last, x.get("hold", HOLD_PAUSE), "pause", x["line"])
            elif mode[0] == "visual":
                run_visual(bd, mode[1], group, held=len(mode) > 2 and mode[2])
            elif mode[0] == "bullets":
                run_bullets(bd, mode[1], group)
            group = []

        for ei, e in enumerate(events):
            if e["e"] == "visual":
                nx = events[ei + 1] if ei + 1 < len(events) else None
                v = e["v"]
                if v["kind"] == "terminal" and v.get("mode") == "cmd" and nx and nx["e"] == "visual" and nx["v"]["kind"] == "terminal" \
                        and nx["v"].get("mode") == "out":
                    cmds = [l.strip() for l in v["text"].split("\n") if l.strip() and not l.strip().startswith("#")]
                    if cmds and all(("$ " + c) in nx["v"]["text"] for c in cmds):
                        continue                  # the transcript that follows shows the same commands
                flush(); mode = ("visual", e["v"], bool(e.get("held")))
            elif e["e"] == "bullets":
                flush(); mode = ("bullets", e)
            elif e["e"] == "keymode":
                flush(); mode = ("key", None); badge = e.get("badge", "")
            elif e["e"] == "topic":
                topic = e["headline"]
                if e["switch"] and mode[0] != "key":
                    flush(); mode = ("key", None)
            else:
                if e["e"] == "narr":
                    e["topic"], e["badge"] = topic, badge
                group.append(e)
        flush()
    # durations, progress
    total = sum(b["est"] for b in bd.beats)
    t = 0.0
    first = {}
    for b in bd.beats:
        b["t0"] = round(t, 2)
        first.setdefault(b["slide"], t)
        t += b["est"]
    for s in bd.slides:
        s["progress"] = round(first.get(s["n"], 0.0) / total, 4) if total else 0
    a, a2, b1, b2, plabel = PARTS[part]
    sb = {
        "id": vid, "version": VERSION, "title": meta["title"], "part": part, "part_label": plabel, "part_name": meta["part_name"],
        "palette": {"accent": a, "accent2": a2, "bg1": b1, "bg2": b2},
        "planned_minutes": meta["planned_minutes"], "chapters": meta["chapters"],
        "script": rel(path), "script_sha1": sha1(text),
        "sections": sec_index, "slides": bd.slides, "beats": bd.beats,
        "est_seconds": round(total, 1), "narration_words": sum(b["words"] for b in bd.beats), "warnings": warnings, "hints": hints,
    }
    for b in sb["beats"]:
        b["h"] = sha1(b["text"])[:8] if b["type"] == "narration" else ""
    video_animplan.annotate(sb)                          # which beat plays which animation (used by tools/video_animate.py)
    return sb


def up_to_date(vid):
    out = STORYBOARDS / f"{vid}.json"
    src = script_path(vid)
    if not out.exists() or not src: return False
    try:
        old = json.loads(out.read_text(encoding="utf-8"))
    except Exception:
        return False
    if old.get("version") != VERSION or old.get("script_sha1") != sha1(src.read_text(encoding="utf-8")): return False
    m = out.stat().st_mtime
    deps = [pathlib.Path(__file__), pathlib.Path(__file__).with_name("video_common.py"), pathlib.Path(__file__).with_name("video_animplan.py")] + [TEXTBOOK / c for c in old.get("chapters", [])]
    return all((not d.exists()) or d.stat().st_mtime <= m for d in deps)


def dump(sb):
    print(f"{sb['id']}  {sb['title']}   part {sb['part']} {sb['part_label']}   est {fmt_dur(sb['est_seconds'])}  "
          f"{len(sb['beats'])} beats, {len(sb['slides'])} slides")
    slides = {s["n"]: s for s in sb["slides"]}
    for b in sb["beats"]:
        s = slides[b["slide"]]
        extra = ""
        if s.get("source"): extra = f"  <- {s['source']['file']}:{s['source']['line']}"
        if s.get("page"): extra += f"  p{s['page'][0]}/{s['page'][1]}"
        if s.get("caption"): extra += "  +caption"
        if "hl" in s: extra += f"  row {s['hl']}"
        txt = b["text"][:70] if b["type"] == "narration" else f"({b['why']} {b['hold']}s)"
        print(f"{b['i']:4d} {fmt_dur(b['t0']):>6} {b['est']:5.1f}s  #{b['slide']:03d} {s['kind']:9s} {txt}{extra}")
    for w in sb["warnings"] + sb.get("hints", []):
        print("  warning:", w)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    force, show = "--force" in sys.argv, "--dump" in sys.argv
    if not args:
        print(__doc__); return 2
    explicit = "all" not in args
    ids = expand_ids(args)
    STORYBOARDS.mkdir(parents=True, exist_ok=True)
    done = skipped = failed = 0
    for vid in ids:
        if not force and not explicit and up_to_date(vid):
            skipped += 1; continue
        try:
            sb = build(vid)
        except SystemExit as e:
            print(e); failed += 1; continue
        except Exception as e:                      # one bad script must not stop a batch
            print(f"{vid}: FAILED to parse: {type(e).__name__}: {e}"); failed += 1
            if explicit: raise
            continue
        (STORYBOARDS / f"{vid}.json").write_text(json.dumps(sb, ensure_ascii=False, indent=1), encoding="utf-8")
        done += 1
        if show: dump(sb)
        else:
            print(f"{vid}: {len(sb['beats'])} beats, {len(sb['slides'])} slides, est {fmt_dur(sb['est_seconds'])}"
                  + (f", {len(sb['warnings']) + len(sb.get('hints', []))} warning(s)" if sb["warnings"] or sb.get("hints") else ""))
    print(f"storyboards: {done} written, {skipped} up to date, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
