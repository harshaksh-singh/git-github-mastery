#!/usr/bin/env python3
"""Render one 1280x720 YouTube thumbnail per video from video/thumbnails/thumbnail-data.json.

    python3 tools/build_thumbnails.py            all videos
    python3 tools/build_thumbnails.py V001 V045  only these

Each entry: {"id":"V001","part":0,"headline":"...", "kicker":"...", "command":"git ...", "motif":"graph|merge|rebase|objects|trees|remote|recover|shield|pipeline|key|search|pack|review|incident|compass"}
Output: video/thumbnails/V001.png ... (and the intermediate SVG-in-HTML under video/thumbnails/html/).
"""
import html, json, pathlib, random, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "video" / "thumbnails"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# one palette per course part: (accent, accent2, background-top, background-bottom, part label)
PARTS = {
    0: ("#F5B700", "#FFE28A", "#14161C", "#232733", "ORIENTATION"),
    1: ("#F05033", "#FF9A80", "#161215", "#2A1D21", "FOUNDATIONS"),
    2: ("#3FB950", "#9BE9A8", "#0F1712", "#1B2A20", "INTEGRATION"),
    3: ("#58A6FF", "#B6DBFF", "#0D1420", "#182739", "RECOVERY"),
    4: ("#BC8CFF", "#E2CCFF", "#15111F", "#261D3A", "INTERNALS"),
    5: ("#F778BA", "#FFC2E0", "#150D13", "#2A1A26", "GITHUB"),
    6: ("#2DD4BF", "#A7F3E8", "#0B1716", "#15302D", "ACTIONS"),
    7: ("#FF5C5C", "#FFB3B3", "#1A0F10", "#33191B", "SECURITY"),
    8: ("#E3B341", "#F6DE9B", "#17140C", "#2D2714", "PRACTICE"),
    9: ("#FF7B39", "#FFC39E", "#1A110B", "#352015", "INCIDENTS"),
    10: ("#D2A8FF", "#F0E0FF", "#141019", "#271D33", "ASSESSMENT"),
    11: ("#79C0FF", "#D0EBFF", "#0C141B", "#172836", "FRONTIER"),
}

def dot(x, y, c, r=17, fill=None):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill or "#0b0d12"}" stroke="{c}" stroke-width="7"/>'
def line(p, c, w=7, dash=""):
    d = "M" + " L".join(f"{x},{y}" for x, y in p)
    return f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round" {dash}/>'
def label(x, y, t, c, bg):
    w = 16 * len(t) + 26
    return (f'<rect x="{x}" y="{y-24}" width="{w}" height="38" rx="8" fill="{c}"/>'
            f'<text x="{x+13}" y="{y+3}" font-family="Menlo,monospace" font-size="24" font-weight="700" fill="{bg}">{html.escape(t)}</text>')
def box(x, y, w, h, c, t, sub=""):
    s = (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="#0b0d12" stroke="{c}" stroke-width="6"/>'
         f'<text x="{x+w/2}" y="{y+h/2+ (0 if sub else 9)}" text-anchor="middle" font-family="Menlo,monospace" font-size="27" font-weight="700" fill="{c}">{html.escape(t)}</text>')
    if sub:
        s += f'<text x="{x+w/2}" y="{y+h/2+34}" text-anchor="middle" font-family="Menlo,monospace" font-size="19" fill="#9aa4af">{html.escape(sub)}</text>'
    return s
def arrow(x1, y1, x2, y2, c):
    return line([(x1, y1), (x2, y2)], c, 6) + f'<circle cx="{x2}" cy="{y2}" r="9" fill="{c}"/>'

def strip(num, a):
    """A row of commits along the bottom; filled dots spell the video number in binary, so no two videos match."""
    xs = [84 + i * 58 for i in range(8)]
    s = f'<path d="M{xs[0]},668 L{xs[-1]},668" stroke="#3a4250" stroke-width="5" stroke-linecap="round"/>'
    for i, x in enumerate(xs):
        on = (num >> (7 - i)) & 1
        s += f'<circle cx="{x}" cy="668" r="11" fill="{a if on else "#0b0d12"}" stroke="{a if on else "#5b6472"}" stroke-width="4"/>'
    return s

def motif(kind, a, a2, bg, rnd):
    """Art in a 520x440 box whose origin is (0,0)."""
    g = "#5b6472"
    n = rnd.randint(3, 4)
    xs = [40 + i * (440 // n) for i in range(n + 1)]
    base = 330
    if kind in ("graph", "merge", "rebase", "recover", "incident"):
        s = line([(xs[0], base), (xs[-1], base)], g) 
        fork = rnd.randint(0, max(0, n - 2)); top = base - rnd.choice([150, 170, 190])
        if kind == "incident": fork = max(fork, 1)               # leave the top-left corner to the warning sign
        if kind == "rebase": fork, top = 0, base - 190           # old commits top left, their copies lower right, never overlapping
        bx = [xs[fork] + 70 + i * 105 for i in range(rnd.randint(2, 3))]
        if bx[-1] > 470: bx = [x - (bx[-1] - 470) for x in bx]     # keep the side branch inside the art box
        if kind == "rebase":
            s += line([(xs[fork], base), (bx[0], top)] + [(x, top) for x in bx], g, 6, 'stroke-dasharray="4 16"')
            nx = [xs[-1] + 0, ]; ry = base - 120
            r0 = min(xs[-1] - 150, 470 - (len(bx) - 1) * 105)       # the rebased copies end inside the art box
            rx = [r0 + i * 105 for i in range(len(bx))]
            s += line([(r0 - 70, base), (rx[0], ry)] + [(x, ry) for x in rx], a)
            s += "".join(dot(x, top, g, 14) for x in bx) + "".join(dot(x, ry, a) for x in rx)
            s += label(min(rx[-1] - 60, 380), ry - 46, "feature", a, bg)
        else:
            s += line([(xs[fork], base), (bx[0], top)] + [(x, top) for x in bx], a)
            if kind == "merge":
                s += line([(bx[-1], top), (xs[-1], base)], a)
            s += "".join(dot(x, top, a) for x in bx)
            s += label(min(bx[-1] - 40, 380), top - 46, "feature", a, bg)
        s += "".join(dot(x, base, a2 if (kind == "merge" and x == xs[-1]) else "#c9d1d9") for x in xs)
        s += label(xs[-1] - 50, base + 62, "main", "#c9d1d9", bg)
        if kind == "recover":
            lx = xs[1] + 40
            s += line([(lx, base + 30), (lx + 150, base + 95)], a2, 6, 'stroke-dasharray="4 14"') + dot(lx + 170, base + 100, a2, 17, a2)
            s += f'<text x="{lx+200}" y="{base+110}" font-family="Menlo,monospace" font-size="26" font-weight="700" fill="{a2}">reflog</text>'
        if kind == "incident":
            s += f'<path d="M90,0 L170,130 L10,130 Z" fill="#0b0d12" stroke="{a2}" stroke-width="9" stroke-linejoin="round"/><text x="90" y="116" text-anchor="middle" font-family="Helvetica" font-size="84" font-weight="900" fill="{a2}">!</text>'
        return s
    if kind == "objects":
        return (box(150, 10, 220, 86, a, "commit", "tree · parent") + arrow(260, 96, 260, 150, g) + box(150, 150, 220, 86, a2, "tree", "names → IDs")
                + arrow(210, 236, 120, 300, g) + arrow(310, 236, 400, 300, g) + box(20, 300, 200, 86, "#c9d1d9", "blob", "contents") + box(300, 300, 200, 86, "#c9d1d9", "blob", "contents"))
    if kind == "trees":
        return (box(0, 150, 160, 130, "#c9d1d9", "working", "tree") + arrow(160, 215, 180, 215, g) + box(180, 150, 160, 130, a, "index", "staged") + arrow(340, 215, 360, 215, g)
                + box(360, 150, 160, 130, a2, "HEAD", "commit") + f'<text x="170" y="120" text-anchor="middle" font-family="Menlo,monospace" font-size="22" fill="{a}">git add →</text><text x="350" y="120" text-anchor="middle" font-family="Menlo,monospace" font-size="22" fill="{a2}">commit →</text>')
    if kind == "remote":
        return (box(140, 0, 240, 100, a, "origin", "bare repository") + box(0, 300, 220, 100, "#c9d1d9", "you", "clone") + box(300, 300, 220, 100, "#c9d1d9", "teammate", "clone")
                + arrow(110, 300, 210, 108, a2) + arrow(310, 108, 410, 300, a) + f'<text x="70" y="210" font-family="Menlo,monospace" font-size="24" font-weight="700" fill="{a2}">push</text><text x="400" y="210" font-family="Menlo,monospace" font-size="24" font-weight="700" fill="{a}">fetch</text>')
    if kind == "shield":
        return (f'<path d="M260,10 L450,80 L450,230 C450,340 360,410 260,440 C160,410 70,340 70,230 L70,80 Z" fill="#0b0d12" stroke="{a}" stroke-width="9" stroke-linejoin="round"/>'
                f'<path d="M180,225 L240,285 L350,160" fill="none" stroke="{a2}" stroke-width="22" stroke-linecap="round" stroke-linejoin="round"/>')
    if kind == "key":
        return (f'<circle cx="150" cy="220" r="95" fill="#0b0d12" stroke="{a}" stroke-width="10"/><circle cx="150" cy="220" r="34" fill="{bg}" stroke="{a}" stroke-width="8"/>'
                + line([(245, 220), (500, 220)], a, 14) + line([(420, 220), (420, 285)], a, 14) + line([(480, 220), (480, 270)], a, 14))
    if kind == "pipeline":
        st = rnd.choice([["push", "build", "test", "deploy"], ["event", "job", "step", "runner"], ["checkout", "cache", "test", "artifact"], ["lint", "test", "build", "release"]])
        hi = rnd.randrange(4)
        s = ""
        for i, t in enumerate(st):
            y = 20 + i * 108
            lit = (i == hi)
            s += box(110, y, 300, 78, a2 if lit else a, t)
            if lit: s += f'<rect x="98" y="{y-12}" width="324" height="102" rx="20" fill="none" stroke="{a2}" stroke-width="4" stroke-dasharray="6 12"/>'

            if i < 3: s += arrow(260, y + 78, 260, y + 104, g)
        return s
    if kind == "search":
        return (line([(40, 330), (480, 330)], g) + "".join(dot(40 + i * 110, 330, "#c9d1d9" if i != 3 else a, 17, None if i != 3 else a) for i in range(5))
                + f'<circle cx="370" cy="160" r="105" fill="none" stroke="{a2}" stroke-width="12"/>' + line([(445, 235), (505, 300)], a2, 16)
                + f'<text x="370" y="180" text-anchor="middle" font-family="Menlo,monospace" font-size="54" font-weight="700" fill="{a}">?</text>')
    if kind == "pack":
        s = ""
        for i in range(4):
            s += f'<rect x="{90+i*14}" y="{40+i*84}" width="{340-i*28}" height="64" rx="10" fill="#0b0d12" stroke="{a if i%2==0 else a2}" stroke-width="6"/>'
            s += f'<text x="260" y="{82+i*84}" text-anchor="middle" font-family="Menlo,monospace" font-size="24" fill="{a if i%2==0 else a2}">{["base object","delta","delta","pack index"][i]}</text>'
        return s
    if kind == "review":
        return (box(20, 30, 480, 300, "#c9d1d9", "", "") + f'<rect x="50" y="70" width="300" height="20" rx="6" fill="#3fb950"/><rect x="50" y="110" width="380" height="20" rx="6" fill="#3fb950"/><rect x="50" y="150" width="240" height="20" rx="6" fill="#f85149"/><rect x="50" y="190" width="340" height="20" rx="6" fill="#5b6472"/><rect x="50" y="230" width="280" height="20" rx="6" fill="#3fb950"/>'
                + f'<circle cx="420" cy="350" r="70" fill="{a}"/><path d="M385,350 L412,378 L458,325" fill="none" stroke="{bg}" stroke-width="16" stroke-linecap="round" stroke-linejoin="round"/>')
    # compass
    return (f'<circle cx="260" cy="220" r="190" fill="#0b0d12" stroke="{a}" stroke-width="9"/><g transform="rotate({rnd.randrange(0, 360, 15)} 260 220)"><path d="M260,60 L310,220 L260,380 L210,220 Z" fill="{a2}"/><path d="M260,60 L310,220 L210,220 Z" fill="{a}"/></g><circle cx="260" cy="220" r="16" fill="{bg}"/>'
            + "".join(f'<circle cx="{260 + 165*__import__("math").cos(k*0.5236):.0f}" cy="{220 + 165*__import__("math").sin(k*0.5236):.0f}" r="{7 if k % 3 == 0 else 4}" fill="{a}"/>' for k in range(12)))

try:                      # exact text widths when Pillow and the system font are available
    from PIL import ImageFont
    _BOLD = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", 200, index=1)
except Exception:         # otherwise a conservative estimate per character
    _BOLD = None

def width(text, size, spacing=0.0):
    """Rendered width in px of one line of bold Helvetica Neue at the given font size."""
    if _BOLD is not None:
        return _BOLD.getlength(text) * size / 200 + spacing * len(text)
    return 0.72 * size * len(text) + spacing * len(text)

def fit(text, max_px, base, spacing=0.0):
    """Largest font size up to base at which every line of text is at most max_px wide."""
    size = base
    while size > 20 and max(width(l, size, spacing) for l in text.split("\n")) > max_px:
        size -= 1
    return size

def page(e):
    a, a2, b1, b2, plabel = PARTS[int(e["part"])]
    rnd = random.Random(e["id"])
    head = e["headline"].upper()
    words = head.split()
    if "\n" not in head and len(words) > 1:   # balance into two lines of the most equal width
        best = None
        for i in range(1, len(words)):
            l1, l2 = " ".join(words[:i]), " ".join(words[i:])
            score = max(width(l1, 100), width(l2, 100))
            if best is None or score < best[0]: best = (score, l1 + "\n" + l2)
        head = best[1]
    hl = head.split("\n"); size = fit(head, 628, 140, -2)   # the diagram starts at x=724; the text ends by x=692
    y0 = 300 - (len(hl) - 1) * size * 0.52
    htxt = "".join(f'<text x="64" y="{y0 + i*size*1.04}" font-family="Helvetica Neue,Arial Black,Arial" font-size="{size}" font-weight="900" letter-spacing="-2" fill="{"#ffffff" if i % 2 == 0 else a}">{html.escape(l)}</text>' for i, l in enumerate(hl))
    ky = y0 + (len(hl) - 1) * size * 1.04 + 78
    cmd = e.get("command", "")
    cmdsvg = ""
    if cmd:
        w = min(620, 22 * len(cmd) + 90)
        cmdsvg = (f'<rect x="64" y="{ky+34}" width="{w}" height="62" rx="12" fill="#0b0d12" stroke="#30363d" stroke-width="3"/>'
                  f'<text x="86" y="{ky+76}" font-family="Menlo,monospace" font-size="{min(32, int((w-60)/ (0.62*len(cmd+"$ "))))}" fill="#c9d1d9"><tspan fill="{a}">$ </tspan>{html.escape(cmd)}</text>')
    grid = "".join(f'<circle cx="{x}" cy="{y}" r="1.6" fill="#ffffff" opacity="0.07"/>' for x in range(20, 1280, 40) for y in range(20, 720, 40))
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720" viewBox="0 0 1280 720">
<defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{b1}"/><stop offset="1" stop-color="{b2}"/></linearGradient>
<radialGradient id="glow" cx="0.78" cy="0.45" r="0.5"><stop offset="0" stop-color="{a}" stop-opacity="0.22"/><stop offset="1" stop-color="{a}" stop-opacity="0"/></radialGradient></defs>
<rect width="1280" height="720" fill="url(#bg)"/>{grid}<rect width="1280" height="720" fill="url(#glow)"/>
<rect x="0" y="0" width="14" height="720" fill="{a}"/>
<rect x="64" y="52" width="{22*len(plabel)+44}" height="52" rx="26" fill="{a}"/><text x="86" y="88" font-family="Helvetica Neue,Arial" font-size="27" font-weight="800" letter-spacing="3" fill="{b1}">{plabel}</text>
<text x="{64+22*len(plabel)+66}" y="88" font-family="Menlo,monospace" font-size="27" font-weight="700" fill="#8b949e">GIT &amp; GITHUB MASTERY</text>
{htxt}
<text x="66" y="{ky}" font-family="Helvetica Neue,Arial" font-size="{fit(e.get("kicker","") or " ", 626, 38)}" font-weight="600" fill="#c9d1d9">{html.escape(e.get("kicker",""))}</text>
{cmdsvg}
<g transform="translate(724,150)">{motif(e.get("motif","graph"), a, a2, b1, rnd)}</g>
{strip(int(e["id"][1:]), a)}
<rect x="1096" y="44" width="128" height="68" rx="14" fill="#0b0d12" stroke="{a}" stroke-width="4"/><text x="1160" y="92" text-anchor="middle" font-family="Menlo,monospace" font-size="40" font-weight="700" fill="{a}">{e["id"][1:]}</text>
</svg>'''
    return f'<!doctype html><html><head><meta charset="utf-8"><style>html,body{{margin:0;background:{b1};overflow:hidden}}svg{{display:block}}</style></head><body>{svg}</body></html>'

def main():
    data = json.loads((OUT / "thumbnail-data.json").read_text(encoding="utf-8"))
    want = set(a for a in sys.argv[1:] if a.startswith("V"))
    (OUT / "html").mkdir(parents=True, exist_ok=True)
    n = 0
    for e in data:
        if want and e["id"] not in want: continue
        h = OUT / "html" / f'{e["id"]}.html'; h.write_text(page(e), encoding="utf-8")
        png = OUT / f'{e["id"]}.png'
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                        "--window-size=1280,720", f"--screenshot={png}", h.as_uri()], capture_output=True, timeout=120)
        n += 1 if png.exists() else 0
    print(f"rendered {n} thumbnail(s)")

if __name__ == "__main__":
    main()
