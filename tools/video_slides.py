#!/usr/bin/env python3
"""Render the slides of a storyboard as 1920x1080 PNG files with headless Chrome.

    python3 tools/video_slides.py V008 V040     these videos
    python3 tools/video_slides.py all           every storyboard (only slides whose content changed are redrawn)
    python3 tools/video_slides.py --force V008  redraw everything
    python3 tools/video_slides.py --jobs 6 all  number of Chrome processes (default 4)

Output: video/production/slides/VNNN/NNN.png and video/production/slides/VNNN/manifest.json
The HTML of each slide is kept in video/production/.cache/html/VNNN/ so a slide can be opened in a browser.
"""
import base64, html, json, os, re, shutil, subprocess, sys, time, unicodedata
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parent))
from video_common import *   # noqa: F401,F403

RENDER_VERSION = 13
CONTENT_W, CONTENT_H, CAPTION_H = 1728, 880, 132      # keep in step with video_storyboard.py
MONO_ADV = 0.6021
E = lambda s: html.escape(str(s), quote=False)


def mono_html(s):
    """Monospace text that stays aligned: every non-ASCII character is put in a cell of exactly 1 or 2 columns."""
    out = []
    for ch in s:
        o = ord(ch)
        if o < 128:
            out.append(E(ch))
        elif o in (0xFE0F, 0x200D) or unicodedata.combining(ch):
            if out and out[-1].endswith("</span>"):
                out[-1] = out[-1][:-7] + ch + "</span>"
        elif unicodedata.east_asian_width(ch) in ("W", "F") or o >= 0x1F000:
            out.append(f'<span class="w2">{ch}</span>')
        else:
            out.append(f'<span class="w1">{ch}</span>')
    return "".join(out)


def mono_width(s):
    n = 0
    for ch in s:
        o = ord(ch)
        if o in (0xFE0F, 0x200D) or unicodedata.combining(ch): continue
        n += 2 if (o >= 128 and (unicodedata.east_asian_width(ch) in ("W", "F") or o >= 0x1F000)) else 1
    return n


def css(pal):
    a, a2, b1, b2 = pal["accent"], pal["accent2"], pal["bg1"], pal["bg2"]
    return f"""
*{{box-sizing:border-box}}
html,body{{margin:0;width:1920px;height:1080px;overflow:hidden;background:{b1}}}
body{{background:linear-gradient(180deg,{b1},{b2});color:#e6edf3;font-family:"Helvetica Neue",Helvetica,Arial,sans-serif;position:relative;-webkit-font-smoothing:antialiased}}
.grid{{position:absolute;inset:0;background-image:radial-gradient(rgba(255,255,255,.065) 2.3px,transparent 2.6px);background-size:60px 60px;background-position:30px 30px}}
.bar{{position:absolute;left:0;top:0;width:18px;height:1080px;background:{a}}}
.hdr{{position:absolute;left:96px;right:96px;top:0;height:100px;display:flex;align-items:center;gap:24px;font:700 25px Menlo,monospace}}
.hdr .course{{color:#8b949e;letter-spacing:1px}}
.hdr .num{{border:3px solid {a};color:{a};border-radius:10px;padding:5px 14px 4px;background:#0b0d12}}
.hdr .ttl{{color:#6e7681;font:500 24px "Helvetica Neue",Helvetica,Arial;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;flex:1;min-width:0}}
.hdr .sec{{color:{a};font:800 24px "Helvetica Neue",Helvetica,Arial;letter-spacing:3px;white-space:nowrap}}
.content{{position:absolute;left:96px;top:112px;width:{CONTENT_W}px;height:{CONTENT_H}px;display:flex;flex-direction:column}}
.main{{flex:1;min-height:0;width:100%;display:flex;flex-direction:column;align-items:safe center;justify-content:safe center;overflow:hidden}}
.main.wide{{overflow:visible}}
.cap{{height:{CAPTION_H - 20}px;margin-top:20px;flex:none;display:flex;align-items:center;background:rgba(11,13,18,.82);border:1px solid #30363d;border-left:10px solid {a};border-radius:12px;padding:0 34px;font-size:35px;line-height:1.28;color:#f0f6fc;font-weight:500}}
.cap div{{display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}}
.prog{{position:absolute;left:0;bottom:0;height:8px;width:100%;background:rgba(255,255,255,.08)}}
.prog i{{display:block;height:100%;background:{a}}}
code{{font-family:Menlo,monospace;font-size:.86em;color:{a2};background:rgba(255,255,255,.07);border-radius:.22em;padding:.06em .28em;white-space:pre-wrap;overflow-wrap:anywhere}}
b{{color:#fff}}
.nw{{white-space:nowrap}}
.w1{{display:inline-block;width:1ch;text-align:center;white-space:pre}}
.w2{{display:inline-block;width:2ch;text-align:center;white-space:pre}}
/* terminal */
.term{{width:100%;background:#0b0d12;border:2px solid #30363d;border-radius:16px;overflow:hidden;box-shadow:0 18px 50px rgba(0,0,0,.45)}}
.term .tb{{height:54px;background:#161b22;border-bottom:2px solid #30363d;display:flex;align-items:center;padding:0 22px;gap:11px;font:500 22px Menlo,monospace;color:#8b949e}}
.term .tb u{{width:17px;height:17px;border-radius:50%;display:block}}
.term .tb .t{{flex:1;text-align:center;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}}
.term .tb .pg{{color:{a};font-weight:700;min-width:60px;text-align:right}}
.term pre{{margin:0;padding:28px 40px;font-family:Menlo,monospace;line-height:1.38;color:#b6bfc9;white-space:pre}}
.term .p{{color:{a};font-weight:700}} .term .c{{color:#ffffff;font-weight:700}} .term .m{{color:#6e7681}}
.term .x{{color:#e3b341}} .term .k{{color:#6e7681}} .term .err{{color:#ff9a8f}} .term .ok{{color:#9be9a8}}
/* diagram */
.dia{{background:rgba(11,13,18,.6);border:1px solid #30363d;border-radius:16px;padding:34px 46px}}
.dia pre{{margin:0;font-family:Menlo,monospace;line-height:1.3;color:#e6edf3;white-space:pre}}
.src{{position:absolute;right:96px;bottom:26px;font:500 20px Menlo,monospace;color:#6e7681}}
/* table */
table{{border-collapse:collapse;width:100%;line-height:1.3;table-layout:fixed}}
table.mono td{{font-family:Menlo,monospace;font-size:.88em;line-height:1.42;border-bottom-color:#21262d}} table.mono td:first-child{{font-weight:700}}
td,th{{overflow-wrap:break-word}}
th{{text-align:left;color:{a};font-size:.74em;letter-spacing:.09em;text-transform:uppercase;padding:.35em .6em .5em;border-bottom:3px solid {a};vertical-align:bottom}}
td{{padding:.42em .6em;border-bottom:1px solid #30363d;vertical-align:top;color:#d5dce4}}
td:first-child{{color:#fff;font-weight:700}}
tr.hl td{{background:{a}26;color:#fff}} tr.hl td:first-child{{box-shadow:inset 8px 0 0 {a}}}
table.has-hl tr:not(.hl) td{{opacity:.5}}
.cards{{width:100%;align-self:stretch;line-height:1.3}}
.cardrow{{background:rgba(11,13,18,.55);border:1px solid #30363d;border-left:10px solid {a}66;border-radius:14px;padding:.55em .9em .5em;margin-bottom:.5em}}
.cardrow.hl{{border-left-color:{a};background:{a}1f}} .cards.has-hl .cardrow:not(.hl){{opacity:.55}}
.cardrow .ct{{font-size:1.25em;font-weight:800;color:#fff;margin-bottom:.3em}}
.cardrow .kv{{display:flex;gap:.9em;padding:.21em 0;border-top:1px solid #21262d}}
.cardrow .k{{flex:none;width:var(--lw);color:{a};font-size:.74em;font-weight:700;letter-spacing:.08em;text-transform:uppercase;padding-top:.3em}}
.cardrow .v{{flex:1;min-width:0;color:#d5dce4;overflow-wrap:anywhere}}
.cards.mono .v{{font-family:Menlo,monospace;font-size:.88em}}
.pgn{{align-self:flex-end;font:700 22px Menlo,monospace;color:{a};margin-top:10px}}
/* bullets */
.bul{{width:100%;align-self:stretch}}
.bul .lead{{font-weight:700;color:#fff;margin-bottom:.7em}}
.bul .it{{display:flex;gap:.62em;margin-bottom:.62em;line-height:1.3;color:#d5dce4}}
.bul .it .mk{{flex:none;width:1.5em;height:1.5em;margin-top:-.1em;border-radius:50%;display:flex;align-items:center;justify-content:center;font:700 .68em Menlo,monospace;background:#0b0d12;border:.14em solid {a};color:{a}}}
.bul .it.dot .mk{{width:.52em;height:.52em;margin:.42em .3em 0 .3em;background:{a};border:none}}
.bul .it.hid{{visibility:hidden}}
.bul .it.old{{opacity:.5}}
.bul .it.cur{{color:#fff}} .bul .it.cur .mk{{background:{a};color:{b1}}}
/* key point */
.key{{width:100%;align-self:stretch;padding:0 30px 0 10px}}
.key .badge{{display:inline-block;background:{a};color:{b1};font-weight:800;font-size:26px;letter-spacing:3px;border-radius:26px;padding:8px 24px;margin-bottom:34px;text-transform:uppercase}}
.key .hd{{color:{a};font-weight:800;font-size:.72em;line-height:1.2;margin-bottom:.55em}}
.key .bd{{color:#fff;font-weight:600;line-height:1.26;letter-spacing:-.01em}}
.key.solo .hd{{color:#fff;font-size:1.5em;letter-spacing:-.02em;margin:0}}
.key .rule{{width:140px;height:8px;background:{a};border-radius:4px;margin-bottom:44px}}
/* callout */
.call{{width:100%;align-self:stretch;padding:0 20px}}
.call .lb{{color:#9aa4af;font-weight:600;font-size:.66em;margin-bottom:.8em}}
.call .lb .pill{{display:inline-block;background:{a};color:{b1};font-weight:800;letter-spacing:2px;border-radius:999px;padding:.2em .8em;margin-right:.5em}}
.call .q{{border-left:12px solid {a};padding:.3em 0 .3em .8em;margin-bottom:.7em;color:#fff;font-weight:600;line-height:1.28}}
.call .tail{{color:#9aa4af;font-size:.6em;margin-top:.4em}}
.call .cd{{font-family:Menlo,monospace;background:#0b0d12;border:2px solid #30363d;border-radius:14px;padding:.5em .8em;margin-bottom:.5em;color:#fff;font-weight:700;font-size:.86em;overflow-wrap:anywhere}}
.call .cd .p{{color:{a}}}
.call .out{{font-family:Menlo,monospace;color:#ff9a8f;font-size:.74em;line-height:1.4;padding:.2em 0 0 .2em;overflow-wrap:anywhere}}
/* cards */
.card{{position:absolute;left:96px;right:96px;top:0;bottom:0;display:flex;flex-direction:column;justify-content:center}}
.card .pill{{align-self:flex-start;background:{a};color:{b1};font-weight:800;font-size:30px;letter-spacing:4px;border-radius:40px;padding:12px 34px}}
.card .row{{display:flex;align-items:center;gap:30px;margin-bottom:60px}}
.card .course{{font:700 30px Menlo,monospace;color:#8b949e}}
.card .big{{font-weight:900;letter-spacing:-.02em;line-height:1.06;color:#fff}}
.card .sub{{font-size:40px;font-weight:600;color:#c9d1d9;margin-top:44px}}
.card .numbox{{position:absolute;right:0;top:66px;border:5px solid {a};border-radius:18px;background:#0b0d12;color:{a};font:700 58px Menlo,monospace;padding:10px 30px}}
.ticks{{display:flex;gap:12px;margin-top:60px}} .ticks i{{display:block;width:70px;height:10px;border-radius:5px;background:rgba(255,255,255,.14)}} .ticks i.on{{background:{a}}} .ticks i.done{{background:{a}66}}
"""


FIT_JS = """<script>(function(){var m=document.querySelector('[data-box]'),r={};if(m){
function over(){return m.scrollHeight>m.clientHeight+1||(!m.classList.contains('wide')&&m.scrollWidth>m.clientWidth+1)}
document.querySelectorAll('[data-fit]').forEach(function(el){var min=parseFloat(el.getAttribute('data-fit')),fs=parseFloat(getComputedStyle(el).fontSize),n=0;
while(over()&&fs>min&&n<300){fs-=1;el.style.fontSize=fs+'px';n++}r.fs=fs;r.shrunk=n});
r.over=over();r.sh=m.scrollHeight;r.ch=m.clientHeight;r.sw=m.scrollWidth;r.cw=m.clientWidth}window.__fit=r})();</script>"""


def term_line(l):
    t, s = l["t"], mono_html(l["s"])
    if t == "cmd":
        m = re.match(r"^(.*?\S)(\s{2,}#.*)$", l["s"])
        if m: s = mono_html(m.group(1)) + f'<span class="m">{mono_html(m.group(2))}</span>'
        return f'<span class="p">$ </span><span class="c">{s}</span>'
    if t == "more": return f'  <span class="c">{s}</span>'
    if t == "wrap":
        cls = "c" if l.get("of") in ("cmd", "more") else ""
        return f'<span class="k">  ↪ </span><span class="{cls}">{s}</span>'
    if t == "cmt": return f'<span class="m">{s}</span>'
    if t == "exit": return f'<span class="x">{s}</span>'
    if t == "ctx": return f'<span class="k">$ {s}</span>'
    if t == "ctx2": return f'<span class="k">{s}</span>'
    if t == "code":
        m = re.match(r"^(\s*)(#.*)$", l["s"])
        if m: return f'{m.group(1)}<span class="m">{mono_html(m.group(2))}</span>'
        return f'<span style="color:#e6edf3">{s}</span>'
    if re.match(r"^(fatal|error|ERROR|remote: error|CONFLICT|hint: |warning): ?", l["s"]) or l["s"].startswith(" ! "):
        return f'<span class="err">{s}</span>'
    return s


def body_html(sb, s):
    k = s["kind"]
    if s.get("_html") is not None:       # the animation layer draws some slide kinds its own way (tools/video_animate.py)
        return s["_html"]
    avail = CONTENT_H - (CAPTION_H if s.get("caption") else 0)
    if k == "terminal":
        title = s.get("title") or ("lab sandbox" if s.get("mode") != "code" else "")
        pg = f'{s["page"][0]}/{s["page"][1]}' if s.get("page") else ""
        lines = "\n".join(term_line(l) for l in s["lines"])
        return (f'<div class="term"><div class="tb"><u style="background:#ff5f57"></u><u style="background:#febc2e"></u><u style="background:#28c840"></u>'
                f'<span class="t">{E(title)}</span><span class="pg">{pg}</span></div><pre style="font-size:{s["fs"]}px">{lines}</pre></div>')
    if k == "diagram":
        lines = s["text"].expandtabs(8).split("\n")
        while lines and not lines[-1].strip(): lines.pop()
        while lines and not lines[0].strip(): lines.pop(0)
        ind = min((len(l) - len(l.lstrip(" ")) for l in lines if l.strip()), default=0)
        lines = [l[ind:].rstrip() for l in lines]
        cols = max(1, max(mono_width(l) for l in lines)); rows = len(lines)
        fs = int(min(44, (CONTENT_W - 96) / (MONO_ADV * cols), (avail - 72) / (1.3 * rows)))
        wide = ""
        if fs < 26 and (avail - 60) / (1.3 * rows) > fs:           # a wide drawing may use the page margins
            fs = int(min(26, (W - 2 * 30 - 2 * 24) / (MONO_ADV * cols), (avail - 60) / (1.3 * rows)))
            wide = ' style="margin:0 -66px;padding:28px 24px"'
        return f'<div class="dia"{wide}><pre data-fit="12" style="font-size:{fs}px">' + "\n".join(mono_html(l) for l in lines) + "</pre></div>"
    if k == "scene":                    # a library scene (tools/anim/scenes.js); the still shows the state after step "upto"
        return f'<div id="scene" style="width:{CONTENT_W}px;height:{avail}px"></div>'
    if k == "table":
        hl = s.get("hl", -1)
        def nw(c):
            c = re.sub(r"<code>([^<]{1,30})</code>", r'<code class="nw">\1</code>', c)
            if s.get("mono"):          # options such as --left-right must not break at their hyphens
                c = re.sub(r"(?<![\w<&/-])([^\s<>]*-[^\s<>]{1,33})(?![^<]*>)", r'<span class="nw">\1</span>', c)
            return c
        rows = "".join(f'<tr class="{"hl" if i == hl else ""}">' + "".join(f"<td>{nw(c)}</td>" for c in r) + "</tr>" for i, r in enumerate(s["rows"]))
        pg = f'<div class="pgn">{s["page"][0]}/{s["page"][1]}</div>' if s.get("page") else ""
        if s.get("layout") == "cards":
            out = [f'<div class="cards{" mono" if s.get("mono") else ""}{" has-hl" if hl >= 0 else ""}" data-fit="24" style="font-size:{s["fs"]}px;--lw:{s.get("label_w", 22)}%">']
            for i, r in enumerate(s["rows"]):
                out.append(f'<div class="cardrow{" hl" if i == hl else ""}"><div class="ct">{r[0]}</div>')
                for hname, c in zip(s["header"][1:], r[1:]):
                    if re.sub(r"<[^>]+>", "", c).strip():
                        out.append(f'<div class="kv"><div class="k">{hname}</div><div class="v">{c}</div></div>')
                out.append("</div>")
            return "".join(out) + f"</div>{pg}"
        cg = "<colgroup>" + "".join(f'<col style="width:{w}%">' for w in s.get("cols", [])) + "</colgroup>"
        return (f'<table data-fit="22" class="{"has-hl" if hl >= 0 else ""}{" mono" if s.get("mono") else ""}" style="font-size:{s["fs"]}px">{cg}<thead><tr>'
                + "".join(f"<th>{c}</th>" for c in s["header"]) + f"</tr></thead><tbody>{rows}</tbody></table>{pg}")
    if k == "bullets":
        out = [f'<div class="bul" data-fit="28" style="font-size:{s["fs"]}px">']
        if s.get("lead"): out.append(f'<div class="lead">{s["lead"]}</div>')
        shown, cur = s.get("shown", len(s["items"])), s.get("current")
        for i, it in enumerate(s["items"]):
            cls = "hid" if i >= shown else ("cur" if cur == i else ("old" if cur is not None else ""))
            if s.get("ordered"):
                out.append(f'<div class="it {cls}"><span class="mk">{s.get("start", 1) + i}</span><div>{it}</div></div>')
            else:
                out.append(f'<div class="it dot {cls}"><span class="mk"></span><div>{it}</div></div>')
        pg = f'<div class="pgn" style="text-align:right">{s["page"][0]}/{s["page"][1]}</div>' if s.get("page") else ""
        return "".join(out) + "</div>" + pg
    if k == "keypoint":
        hd, bd = s.get("headline", ""), s.get("body", "")
        badge = f'<div><span class="badge">{E(s["badge"])}</span></div>' if s.get("badge") else ""
        if hd and not bd:
            return f'<div class="key solo" data-fit="40" style="font-size:62px">{badge}<div class="rule"></div><div class="hd">{hd}</div></div>'
        n = len(re.sub(r"<[^>]+>", "", bd))
        fs = 68 if n < 90 else (60 if n < 150 else 52)
        return (f'<div class="key" data-fit="38" style="font-size:{fs}px">{badge}<div class="rule"></div>'
                + (f'<div class="hd">{hd}</div>' if hd else "") + f'<div class="bd">{bd}</div></div>')
    if k == "callout":
        label = s.get("label", "")
        quotes, code = s.get("quotes", []), s.get("code", [])
        n = sum(len(re.sub(r"<[^>]+>", "", q)) for q in quotes) + sum(len(c) for c in code)
        fs = 66 if n < 80 else (56 if n < 170 else (48 if n < 300 else 42))
        out = [f'<div class="call" data-fit="32" style="font-size:{fs}px">']
        cmd_label = re.fullmatch(r"<code>(.+?)</code>", label or "")
        qm = re.match(r"^(Q\d+)$", re.sub(r"<[^>]+>", "", label or "").strip())
        if cmd_label and quotes:             # a command and what it printed
            out.append(f'<div class="cd"><span class="p">$ </span>{cmd_label.group(1)}</div>')
            out += [f'<div class="out">{re.sub(r"</?code>", "", q)}</div>' for q in quotes]
        else:
            if qm: out.append(f'<div class="lb"><span class="pill">{qm.group(1)}</span>Interview question</div>')
            elif label: out.append(f'<div class="lb">{label}</div>')
            for q in quotes:
                out.append(f'<div class="q">{"“" if s.get("quoted") else ""}{q}{"”" if s.get("quoted") else ""}</div>')
            for c in code:
                pr = '<span class="p">$ </span>' if re.match(r"^(git|gh|labs/|ssh|cd|ls|cat|curl|scalar|make|python|pip|docker)\b", c) else ""
                out.append(f'<div class="cd">{pr}{mono_html(c)}</div>')
            if s.get("tail"): out.append(f'<div class="tail">{s["tail"]}</div>')
        return "".join(out) + "</div>"
    raise ValueError(f"unknown slide kind {k}")


def pretty_section(name):
    return name


def slide_html(sb, s, thumb_uri=None, scene_script=True):
    pal, vid = sb["palette"], sb["id"]
    head = f'<!doctype html><html><head><meta charset="utf-8"><style>{css(pal)}</style></head><body>'
    k = s["kind"]
    if k == "title" and thumb_uri:
        return head + f'<img src="{thumb_uri}" style="position:absolute;left:0;top:0;width:1920px;height:1080px"></body></html>'
    frame = '<div class="grid"></div><div class="bar"></div>'
    if k == "title":
        n = len(sb["title"])
        fs = 124 if n < 30 else (104 if n < 55 else (88 if n < 85 else (74 if n < 120 else 62)))
        return (head + frame + f'<div class="card"><div class="numbox">{vid[1:]}</div><div class="row"><span class="pill">{E(sb["part_label"])}</span>'
                f'<span class="course">{E(COURSE_NAME)}</span></div><div data-box style="max-height:600px;overflow:hidden;padding-right:40px">'
                f'<div class="big" data-fit="50" style="font-size:{fs}px">{E(sb["title"])}</div></div>'
                f'<div class="sub">{E("Part " + str(sb["part"]) + (": " + sb["part_name"] if sb.get("part_name") else ""))}</div></div>'
                + FIT_JS + "</body></html>")
    if k == "section":
        ticks = "".join(f'<i class="{"on" if i + 1 == s["index"] else ("done" if i + 1 < s["index"] else "")}"></i>' for i in range(s["count"]))
        return (head + frame + f'<div class="card"><div class="numbox">{vid[1:]}</div><div class="row"><span class="pill">{s["index"]} / {s["count"]}</span>'
                f'<span class="course">{E(COURSE_NAME)}</span></div><div class="big" style="font-size:{128 if len(s["name"]) < 18 else 104}px">{E(s["name"].title())}</div>'
                f'<div class="sub" style="color:#8b949e;max-width:1500px">{E(sb["title"])}</div><div class="ticks">{ticks}</div></div>'
                f'<div class="prog"><i style="width:{s.get("progress", 0) * 100:.2f}%"></i></div></body></html>')
    cap = f'<div class="cap"><div>{s["caption"]}</div></div>' if s.get("caption") else ""
    body = body_html(sb, s)
    src = ""
    if s.get("source"):
        src = f'<div class="src">textbook section {E(s["source"]["section"])}</div>'
    tail = ""
    if k == "scene" and scene_script:
        cfg = {"fx": "scene", "scene": s["scene"], "params": s.get("params", {}), "steps": s.get("steps"), "from": s["upto"], "to": s["upto"], "palette": pal,
               "h": CONTENT_H - (CAPTION_H if s.get("caption") else 0)}
        tail = f"<script>{anim_lib()}</script><script>A.run({json.dumps(cfg, ensure_ascii=False)})</script>"
    return (head + frame +
            f'<div class="hdr"><span class="num">{vid}</span><span class="course">{E(COURSE_NAME)}</span><span class="ttl">{E(sb["title"])}</span>'
            f'<span class="sec">{E(pretty_section(s["section"]))}</span></div>'
            f'<div class="content"><div class="main{" wide" if "margin:0 -66px" in body else ""}" data-box>{body}</div>{cap}</div>{src}'
            f'<div class="prog"><i style="width:{s.get("progress", 0) * 100:.2f}%"></i></div>' + FIT_JS + tail + "</body></html>")


def shoot(jobs, nproc):
    """jobs: [(html path, png path)] -> {png: fit dict or None on failure}"""
    results = {}
    node = shutil.which("node")
    if not jobs:
        return results
    if node:
        CACHE.mkdir(parents=True, exist_ok=True)
        nproc = max(1, min(nproc, (len(jobs) + 39) // 40))
        chunks = [jobs[i::nproc] for i in range(nproc)]

        def run(ix):
            jp, rp = CACHE / f"shoot-{os.getpid()}-{ix}.json", CACHE / f"shoot-{os.getpid()}-{ix}.out.json"
            jp.write_text(json.dumps({"chrome": CHROME, "profile": str(CACHE / f"chrome-{os.getpid()}-{ix}"), "width": W, "height": H,
                                      "jobs": [{"html": str(h), "png": str(p)} for h, p in chunks[ix]]}), encoding="utf-8")
            try:
                subprocess.run([node, str(ROOT / "tools" / "video_shoot.mjs"), str(jp), str(rp)], capture_output=True, timeout=60 + 3 * len(chunks[ix]))
            except subprocess.TimeoutExpired:
                pass
            out = []
            if rp.exists():
                try: out = json.loads(rp.read_text(encoding="utf-8"))
                except Exception: out = []
            for f in (jp, rp):
                try: f.unlink()
                except OSError: pass
            shutil.rmtree(CACHE / f"chrome-{os.getpid()}-{ix}", ignore_errors=True)
            return out

        with ThreadPoolExecutor(nproc) as ex:
            for out in ex.map(run, range(nproc)):
                for r in out:
                    if r.get("ok"): results[r["png"]] = r.get("fit") or {}
    # anything the fast path missed: one Chrome launch per slide
    for h, p in jobs:
        if str(p) in results and pathlib.Path(p).exists():
            continue
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                        f"--window-size={W},{H}", f"--screenshot={p}", pathlib.Path(h).as_uri()], capture_output=True, timeout=120)
        results[str(p)] = {} if pathlib.Path(p).exists() else None
    return results


def plan(vid, force=False):
    """-> (storyboard, jobs, manifest, new hashes)"""
    sb = load_storyboard(vid)
    out = SLIDES / vid
    hdir = CACHE / "html" / vid
    out.mkdir(parents=True, exist_ok=True); hdir.mkdir(parents=True, exist_ok=True)
    mpath = out / "manifest.json"
    try:
        manifest = json.loads(mpath.read_text(encoding="utf-8")) if mpath.exists() else {}
    except Exception:
        manifest = {}
    old = manifest.get("slides", {})
    thumb = thumb_path(vid)
    thumb_uri = None
    if thumb:
        thumb_uri = "data:image/png;base64," + base64.b64encode(thumb.read_bytes()).decode("ascii")
    jobs, hashes = [], {}
    for s in sb["slides"]:
        key = f'{s["n"]:03d}'
        doc = slide_html(sb, s, thumb_uri)
        hsh = sha1(f"{RENDER_VERSION}\n{doc}")
        hashes[key] = hsh
        png = out / f"{key}.png"
        if not force and png.exists() and old.get(key, {}).get("hash") == hsh:
            continue
        hp = hdir / f"{key}.html"
        hp.write_text(doc, encoding="utf-8")
        jobs.append((hp, png))
    return sb, jobs, old, hashes


def finish(vid, sb, jobs, old, hashes, results):
    out = SLIDES / vid
    slides, bad = {}, []
    for s in sb["slides"]:
        key = f'{s["n"]:03d}'
        png = out / f"{key}.png"
        fit = results.get(str(png), old.get(key, {}).get("fit", {})) if (out / f"{key}.png").exists() else None
        if fit is None or not png.exists():
            bad.append(key); continue
        slides[key] = {"hash": hashes[key], "kind": s["kind"], "fit": fit}
    for p in out.glob("[0-9][0-9][0-9].png"):
        if p.stem not in hashes: p.unlink()
    (out / "manifest.json").write_text(json.dumps({"id": vid, "render_version": RENDER_VERSION, "count": len(slides),
                                                   "storyboard_sha1": sha1(json.dumps(sb["slides"], sort_keys=True)),
                                                   "slides": slides}, indent=1), encoding="utf-8")
    over = [k for k, v in slides.items() if v["fit"].get("over")]
    small = [k for k, v in slides.items() if v["fit"].get("shrunk", 0) > 0]
    return bad, over, small


def main():
    argv = sys.argv[1:]
    force = "--force" in argv
    nproc = 4
    if "--jobs" in argv:
        nproc = int(argv[argv.index("--jobs") + 1]); del argv[argv.index("--jobs"):argv.index("--jobs") + 2]
    args = [a for a in argv if not a.startswith("--")]
    if not args:
        print(__doc__); return 2
    ids = expand_ids(args, have=lambda: sorted(p.stem for p in STORYBOARDS.glob("V[0-9][0-9][0-9].json")))
    t0 = time.time()
    plans, jobs = {}, []
    for vid in ids:
        try:
            plans[vid] = plan(vid, force)
        except SystemExit as e:
            print(e); continue
        jobs += plans[vid][1]
    total = sum(len(p[0]["slides"]) for p in plans.values())
    print(f"{len(plans)} video(s), {total} slides, {len(jobs)} to render ...", flush=True)
    results = {}
    B = 400                                  # render in batches so an interrupted run keeps its work
    todo = list(plans)
    while todo:
        batch, n = [], 0
        while todo and (n == 0 or n + len(plans[todo[0]][1]) <= B):
            v = todo.pop(0); batch.append(v); n += len(plans[v][1])
        res = shoot([j for v in batch for j in plans[v][1]], nproc)
        for v in batch:
            sb, vj, old, hashes = plans[v]
            bad, over, small = finish(v, sb, vj, old, hashes, res)
            msg = f"{v}: {len(sb['slides'])} slides, {len(vj)} rendered"
            if bad: msg += f", FAILED: {' '.join(bad)}"
            if over: msg += f", content overflows on: {' '.join(over)}"
            if small: msg += f", auto-shrunk: {' '.join(small)}"
            if vj or bad or over: print(msg, flush=True)
    print(f"done in {time.time() - t0:.1f} s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
