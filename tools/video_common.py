#!/usr/bin/env python3
"""Shared paths, palette and small helpers for the video production tools.

    tools/video_storyboard.py   script  -> storyboard JSON
    tools/video_slides.py       storyboard -> 1920x1080 PNG slides
    tools/video_booth.py        recording booth (local web page + server)
    tools/video_build.py        recording + slides -> MP4, SRT, chapters
"""
import hashlib, importlib.util, json, os, pathlib, re, shutil, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
VIDEO = ROOT / "video"
SCRIPTS = VIDEO / "scripts"
THUMBS = VIDEO / "thumbnails"
TEXTBOOK = ROOT / "textbook"
PROD = VIDEO / "production"
# VIDEO_WORK_DIR moves storyboards, slides and animation clips somewhere else (the animation demo and the self-test use it,
# so that they never touch the course's own files); VIDEO_SCRIPTS_DIR is searched for scripts before video/scripts.
_WORK = os.environ.get("VIDEO_WORK_DIR")
STORYBOARDS = (pathlib.Path(_WORK) if _WORK else PROD) / "storyboards"
SLIDES = (pathlib.Path(_WORK) if _WORK else PROD) / "slides"
ANIM = (pathlib.Path(_WORK) if _WORK else PROD) / "anim"
ANIM_JS = ROOT / "tools" / "anim"
# the self-test points these two somewhere else so that it never touches real recordings or videos
RECORDINGS = pathlib.Path(os.environ.get("VIDEO_RECORDINGS_DIR") or PROD / "recordings")
OUT = pathlib.Path(os.environ.get("VIDEO_OUT_DIR") or PROD / "out")
BOOTH = PROD / "booth"
CACHE = (pathlib.Path(_WORK) / ".cache") if _WORK else PROD / ".cache"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
COURSE_NAME = "GIT & GITHUB MASTERY"

W, H, FPS = 1920, 1080, 30
WPM = 150                       # words per minute used for estimated durations

# one palette per course part: (accent, accent2, background-top, background-bottom, label)
_FALLBACK_PARTS = {
    0: ("#F5B700", "#FFE28A", "#14161C", "#232733", "ORIENTATION"),
    1: ("#F05033", "#FF9A80", "#161215", "#2A1D21", "FOUNDATIONS"),
    2: ("#3FB950", "#9BE9A8", "#0F1712", "#1B2A20", "INTEGRATION"),
    3: ("#58A6FF", "#B6DBFF", "#0D1420", "#182739", "RECOVERY"),
    4: ("#BC8CFF", "#E2CCFF", "#15111F", "#261D3A", "INTERNALS"),
    5: ("#F0F6FC", "#9AA4AF", "#0D1117", "#1C2430", "GITHUB"),
    6: ("#2DD4BF", "#A7F3E8", "#0B1716", "#15302D", "ACTIONS"),
    7: ("#FF5C5C", "#FFB3B3", "#1A0F10", "#33191B", "SECURITY"),
    8: ("#E3B341", "#F6DE9B", "#17140C", "#2D2714", "PRACTICE"),
    9: ("#FF7B39", "#FFC39E", "#1A110B", "#352015", "INCIDENTS"),
    10: ("#D2A8FF", "#F0E0FF", "#141019", "#271D33", "ASSESSMENT"),
    11: ("#79C0FF", "#D0EBFF", "#0C141B", "#172836", "FRONTIER"),
}


def load_parts():
    """The palette lives in tools/build_thumbnails.py; read it from there so videos match thumbnails."""
    try:
        spec = importlib.util.spec_from_file_location("build_thumbnails", ROOT / "tools" / "build_thumbnails.py")
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        return dict(mod.PARTS)
    except Exception:
        return dict(_FALLBACK_PARTS)


PARTS = load_parts()


def vid_norm(s):
    m = re.fullmatch(r"[Vv]?(\d{1,3})", s.strip())
    if not m:
        raise SystemExit(f"not a video id: {s!r} (expected V001 ... V201)")
    return f"V{int(m.group(1)):03d}"


def script_path(vid):
    extra = os.environ.get("VIDEO_SCRIPTS_DIR")
    hits = sorted(pathlib.Path(extra).glob(f"{vid}-*.md")) if extra else []
    hits = hits or sorted(SCRIPTS.glob(f"{vid}-*.md"))
    return hits[0] if hits else None


def all_script_ids():
    return sorted({p.name[:4] for p in SCRIPTS.glob("V[0-9][0-9][0-9]-*.md")})


def expand_ids(args, have=None):
    """'all', 'V008', '8', 'V010-V020' -> list of ids."""
    out = []
    for a in args:
        if a == "all":
            out += have() if have else all_script_ids()
        elif re.fullmatch(r"[Vv]?\d+\s*-\s*[Vv]?\d+", a):
            lo, hi = [int(x) for x in re.findall(r"\d+", a)]
            ids = set(have() if have else all_script_ids())
            out += [f"V{n:03d}" for n in range(lo, hi + 1) if f"V{n:03d}" in ids]
        else:
            out.append(vid_norm(a))
    seen, res = set(), []
    for v in out:
        if v not in seen:
            seen.add(v); res.append(v)
    return res


def sha1(data):
    if isinstance(data, str):
        data = data.encode("utf-8")
    return hashlib.sha1(data).hexdigest()


def file_sha1(path):
    h = hashlib.sha1()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def find_tool(name):
    """ffmpeg / ffprobe may be installed after the shell started: look in the usual Homebrew places too."""
    p = shutil.which(name)
    if p:
        return p
    for d in ("/opt/homebrew/bin", "/usr/local/bin"):
        q = pathlib.Path(d) / name
        if q.exists():
            return str(q)
    return None


# engine, the scenes of batch one (generalized since), the schematic scenes (scenes2.js), the Git and GitHub topic scenes (scenes3.js), the mascot
ANIM_FILES = tuple(f for f in ("engine.js", "scenes.js", "scenes2.js", "scenes3.js", "mascot.js") if (ANIM_JS / f).exists())


def anim_lib():
    """The JavaScript of the animation layer (engine, explainer scenes, mascot) as one string."""
    return "\n".join((ANIM_JS / f).read_text(encoding="utf-8") for f in ANIM_FILES)


def load_storyboard(vid):
    p = STORYBOARDS / f"{vid}.json"
    if not p.exists():
        raise SystemExit(f"{vid}: no storyboard. Run: video/production/make.sh storyboard {vid}")
    return json.loads(p.read_text(encoding="utf-8"))


def thumb_path(vid):
    p = THUMBS / f"{vid}.png"
    return p if p.exists() else None


def fmt_dur(sec):
    sec = int(round(sec))
    return f"{sec // 3600}:{sec % 3600 // 60:02d}:{sec % 60:02d}" if sec >= 3600 else f"{sec // 60}:{sec % 60:02d}"


def rel(p):
    try:
        return str(pathlib.Path(p).resolve().relative_to(ROOT))
    except Exception:
        return str(p)
