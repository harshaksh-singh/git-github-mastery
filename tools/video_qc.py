#!/usr/bin/env python3
"""Quality control of finished videos: measure everything that can be measured, and say so in a report.

    python3 tools/video_qc.py V008            check out/V008.mp4 and its .srt, .chapters.txt, .build.json, thumbnail, metadata
    python3 tools/video_qc.py V010-V020       a range          python3 tools/video_qc.py all      every video of the course
    python3 tools/video_qc.py --selftest      pure tests of the parsers (no video is read)
    video/production/make.sh qc V008|range|all

Options:  --deep     decode every frame of the picture (about half a minute more per video) instead of the key frames only
          --summary  write the summary table again from the reports on disk, check nothing

Writes video/production/out/qc/VNNN.qc.json (every item: what was measured, the threshold, PASS / FAIL / WARN / N/A) and
video/production/out/QC-SUMMARY.md (one row per video).  Exit code 1 if a checked video fails.  A video without an MP4 is
"not built", which is not a failure.

It only reads.  Nothing is built, spoken, rendered or re-encoded; ffmpeg runs one analysis at a time, at low priority.
The item numbers (A1, B4, ...) are those of video/production/QC_CHECKLIST.md.  What this tool cannot check (how the voice
sounds, whether a slide is correct, whether an answer is shown too early) is listed there as work for a person.
"""
import datetime, hashlib, inspect, json, os, re, struct, subprocess, sys, time

sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parent))
from video_common import *   # noqa: E402,F401,F403
import video_build as vb     # noqa: E402   the builder's own helpers are used, never copied: speakable, spoken_chunks, tts_path, ...

QC_VERSION = 1

# ---- thresholds: every number that decides PASS or FAIL is here, with its reason ----------------------------------------
# A. file
AV_DUR_TOL = 0.10            # s: video and audio stream may differ by this much (the builder's own check uses the same)
BUILD_DUR_TOL = 0.10         # s: container duration against the length the builder recorded in .build.json
FRAME_TIME_TOL = 0.001       # s: a frame may sit this far from its 1/30 s slot and the video still counts as constant frame
                             #    rate.  Tuned from 0 (exact): the builder joins separately encoded segments, and at a join a
                             #    frame is 0.3 to 0.7 ms early (measured on V001: 10 of 33,981 frames).  Far below one frame.
FPS_AVG_TOL = 0.01           # frames per second: average frame rate against 30
# B. audio
LOUDNESS_FALLBACK = (-16.0, -1.5)   # LUFS, dBTP: used only if the target cannot be read from loudnorm() in video_build.py
LOUDNESS_WINDOW = 1.0        # LU: integrated loudness must be within target +/- this (EBU R128 allows +/- 1 LU for short material)
TRUE_PEAK_MAX = -1.0         # dBTP: highest true peak allowed.  The builder aims at -1.5 on the uncompressed sound; the AAC
                             #    encoder and the mixed-in sound effects may add a little, so the limit is the usual streaming
                             #    ceiling of -1 dBTP, not the builder's own target.  (Since 2026-10-07 the builder also holds the
                             #    finished, encoded track at -1.5 dBTP or below, seal_audio(); its targets did not change.)
CLIP_SAMPLE_PEAK = -0.1      # dBFS: a sample peak at or above this counts as clipping
SILENCE_NOISE_DB = -30       # dB: below this the sound counts as silence.  Not lower, because the reveal sounds (pop, tick,
                             #    whoosh; peaks near -28 dB at most) are mixed into holds and are not narration.
SILENCE_MIN = 0.25           # s: shortest silence ffmpeg reports (short ones are needed for the hold check C4)
SILENCE_LIST = 1.0           # s: silences at least this long are listed in the report
SILENCE_MARGIN = 0.75        # s: an expected silence (hold, lead) explains this much more on each side: the 0.3 s gap the
                             #    builder puts after every beat plus the voice's own quiet start and end
SILENCE_WARN = 2.5           # s: unexplained silence longer than this is a warning
SILENCE_FAIL = 6.0           # s: ... and longer than this a failure
# C. narration
# The pace bounds are the builder's own (tools/video_build.py, pace_fault): it refuses a voice clip outside them, and this check
# judges every beat by the same rule, so the two can never disagree.  The reasons for the values:
PACE_FACTOR = vb.PACE_FACTOR # a beat's words per second must be within these factors of the configured rate (165 wpm is
                             #    2.75 words/s, so 1.51 to 4.54).  Tuned from 0.70 to 1.30: on 423 verified clips of eight words
                             #    or more the pace runs from 1.65 ("Read sections 26.6 to 26.9 of Chapter 26": numbers are long
                             #    words) to 4.44 ("And the start that is the wrong way round": nine short words), median 2.94.
                             #    Clips that really are cut short or padded lie far outside (5.6 and more, 1.2 and less).
PACE_LETTERS = vb.PACE_LETTERS   # letters per second of a beat (a digit counts as four letters: "7" is said "seven").  Words differ
                             #    in length, letters hardly: verified clips run from 9.0 to 16.2 (99 %), median 13.2.  A beat
                             #    fails if its words OR its letters per second are outside.
PACE_MIN_WORDS = vb.PACE_MIN_WORDS   # beats with fewer spoken words are judged by the wide bounds below: one long or short word
                             #    moves their pace a lot
PACE_FLOOR_WPS = vb.PACE_FLOOR_WPS   # no beat of any length may be faster than this (the only bound for a short beat of a recorded narration)
PACE_SHORT_FAST = vb.PACE_SHORT_FAST   # (words/s, letters/s) a short beat of the computer voice must not exceed, either of them: 5.4 and 19
PACE_SHORT_SLOW = vb.PACE_SHORT_SLOW   # (words/s, letters/s): a short beat is too slow if it is under both: 1.3 and 6.  Tuned on 8 October 2026
                             #    from "4 to 38 letters/s, under 10 words/s", which passed four marked clips that were cut short
                             #    (22.9 to 35.2 letters/s; whole takes of the same texts: 12.4 to 16.9).  The 588 genuine short clips
                             #    run from 1.04 to 4.89 words/s and 4.9 to 18.2 letters/s; twelve were spoken again to confirm.
                             #    History of the lower bound:
                             #    Added after the first run: "You should now be able to say:" lasts 19 s in eighteen of the older
                             #    videos (2 s as a verified clip), and with no bound for short beats nothing reported it.  The 39
                             #    verified short clips run from 9.0 to 17.0 letters per second.
PACE_WIDE = vb.PACE_WIDE     # a clip that came vb.SAME_TAKES times with one length, clean in sound, is accepted by the builder
                             #    outside the bounds above, up to this factor (1.31 to 5.22 words/s, 6.96 to 21.85 letters/s): three
                             #    equal takes are better evidence than a bound made from word and letter counts.  Its .ok mark says
                             #    so (vb.MARK_THREE).  C1 and C2 do not fail such a beat; they list it as a warning with its pace,
                             #    for a person to listen to.  Measured on 8 October 2026: the two sentences that repeat outside
                             #    the bounds are 2 and 3 % outside (4.63 words/s; 19.6 letters/s), the fastest of 7,841 verified
                             #    whole takes run at 4.51 words/s and 18.6 letters/s, clips known to be cut short begin 23 % outside.
PACE_HUMAN_WPS = (1.2, 4.5)  # words per second for a recorded (human) narration
CLIP_LEN_TOL = 0.06          # s: beat length in the video against the length rebuilt from the cached, verified clips
                             #    (beat starts are recorded to 0.01 s; two of them and rounding to frames give 0.05)
HOLD_MIN = 1.5               # s: holds at least this long are checked for being silent in the sound track
HOLD_SILENT_SHARE = 0.80     # share of such a hold that must be silent (the rest: reveal sounds)
# D. picture
FRAME_EVERY = 30             # s between sampled frames
FRAME_W, FRAME_H = 320, 180  # sampled frames are measured at this size, luma only
EDGE_STEP = 8                # luma steps between horizontal neighbours that count as an edge (text, lines)
FRAME_MIN_DETAIL = 1.0       # % of pixels that are edges; below this a frame counts as blank (a flat colour or a bare
                             #    gradient).  Real slides measured 3.5 % to 18 % on V001; the least detailed sampled frame of any video checked: 2.8 %.
BLACK_MIN = 0.5              # s: shortest black stretch reported by blackdetect
BLACK_PIC_TH, BLACK_PIX_TH = 0.98, 0.10   # blackdetect: share of dark pixels for a black frame, and what counts as dark
# E. subtitles
SRT_TAIL_TOL = 0.5           # s: the last cue may end this long after the video
SRT_LINE_MAX = 42            # characters per subtitle line (the usual broadcast and Netflix limit); warning
SRT_LINES_MAX = 2            # lines per cue; warning
SRT_CPS_MAX = 20.0           # characters per second of a cue (adult reading speed); warning
SRT_MIN_COVERAGE = 100.0     # % of the storyboard's narration that must be found, in order, in the cue text
SRT_FORBIDDEN = (("[ANIMATION]", r"\[ANIMATION\]"), ("[PAUSE]", r"\[PAUSE\]"), ("a direction in capitals in square brackets", r"\[[A-Z][A-Z ]{2,}\]"),
                 ("** (bold marker)", r"(?<![\w/*])\*\*(?=\w)|(?<=\w)\*\*(?![\w/*])"), ("backtick", r"`"), ("HTML tag", r"</?(?:i|b|u|font)\b[^>]*>"))
# "**" was tuned from "any two stars" to "two stars that open or close a word": the narration of V087 names the glob pattern
# docs/** ("write docs/**."), which is script text, not markup.  A star pattern such as **/*.py or docs/** is not flagged.
# F. chapters and metadata (YouTube Help, "video chapters": first at 0:00, at least three, ascending, at least 10 s each)
CHAPTERS_MIN = 3
CHAPTER_MIN_SECONDS = 10
CHAPTER_TITLE_MAX = 100      # characters; a chapter line must also stay readable in the player
YT_TITLE_MAX = 100           # characters (YouTube's limit for a title)
YT_DESC_MAX = 5000           # characters (YouTube's limit for a description); checked with the chapter list added
# G. thumbnail
THUMB_SIZE = (1280, 720)
THUMB_MAX_BYTES = 2 * 1024 * 1024
# I. build
VOICE_FIX_EPOCH = 1791340773     # 2026-10-07 08:09:33 local: the modification time of tools/video_build.py when the voice check
                                 # (every spoken piece is made twice and marked ".ok", see tts()) went in.  A video whose build
                                 # started before this has narration from before the voice fix.  Recorded, not read live, so that
                                 # a later unrelated edit of the builder does not turn every video red; change it only when the
                                 # voice step itself is fixed again.
REPORT_AFTER_MP4_MAX = 180       # s: the .build.json is written right after the MP4; a larger distance means they do not belong together
FF_TIMEOUT = 110                 # s for one ffmpeg analysis (they take 1 to 5 s on an idle machine); tried a second time with twice
                                 # this before the item is reported as "did not finish".  Tuned from 100 s without a second try:
                                 # with three builds running (load average above 50) the audio pass of V001 once ran out of time.
MAX_LISTED = 6                   # entries of a list shown in the summary table (the .qc.json has all of them)

QC_DIR = OUT / "qc"
SUMMARY = OUT / "QC-SUMMARY.md"
EMOJI = re.compile("[\U0001F000-\U0001FAFF\u2600-\u27BF\u2B00-\u2BFF\uFE0F\u200D]")
GROUPS = {"A": "File and encoding", "B": "Audio", "C": "Narration against picture", "D": "Picture", "E": "Subtitles",
          "F": "Chapters and metadata", "G": "Thumbnail", "I": "Build record"}


# ---- parsers (pure: tested by --selftest) ------------------------------------------------------------------------------
def srt_seconds(s):
    h, m, rest = s.strip().split(":")
    sec, ms = rest.split(",")
    return int(h) * 3600 + int(m) * 60 + int(sec) + int(ms) / 1000


def parse_srt(text):
    """-> (cues [{"n", "start", "end", "lines"}], problems [str]).  A block that cannot be read is a problem, not a crash."""
    cues, problems = [], []
    blocks = [b for b in re.split(r"\n[ \t]*\n", text.replace("\r\n", "\n").replace("\ufeff", "").strip("\n")) if b.strip()]
    for k, block in enumerate(blocks, 1):
        lines = block.split("\n")
        if len(lines) < 2:
            problems.append(f"block {k}: too short: {block[:40]!r}"); continue
        m = re.fullmatch(r"\s*(\d\d+:\d\d:\d\d,\d\d\d)\s*-->\s*(\d\d+:\d\d:\d\d,\d\d\d)\s*", lines[1])
        if not re.fullmatch(r"\s*\d+\s*", lines[0]) or not m:
            problems.append(f"block {k}: no number or no time line: {' / '.join(lines[:2])[:60]!r}"); continue
        cues.append({"n": int(lines[0]), "start": srt_seconds(m.group(1)), "end": srt_seconds(m.group(2)), "lines": lines[2:]})
    for k, c in enumerate(cues, 1):
        if c["n"] != k:
            problems.append(f"cue {c['n']} stands at position {k}: numbers are not 1, 2, 3, ..."); break
    return cues, problems


def parse_chapters(text):
    """-> (chapters [(seconds, title)], problems).  Lines are 'M:SS Title' or 'H:MM:SS Title'."""
    ch, problems = [], []
    for k, line in enumerate([l for l in text.splitlines() if l.strip()], 1):
        m = re.fullmatch(r"(?:(\d+):)?(\d{1,2}):(\d\d)(?:\s+(.*))?", line.strip())
        if not m:
            problems.append(f"line {k} is not 'M:SS Title': {line[:50]!r}"); continue
        ch.append((int(m.group(1) or 0) * 3600 + int(m.group(2)) * 60 + int(m.group(3)), (m.group(4) or "").strip()))
    return ch, problems


def chapter_problems(ch, total):
    """YouTube's rules for a chapter list -> {rule: [problem, ...]} with only the broken rules."""
    bad = {}
    add = lambda rule, msg: bad.setdefault(rule, []).append(msg)
    if not ch or ch[0][0] != 0: add("first", "the first chapter does not start at 0:00")
    if len(ch) < CHAPTERS_MIN: add("count", f"{len(ch)} chapter(s), at least {CHAPTERS_MIN} are needed")
    for (a, ta), (b, tb) in zip(ch, ch[1:]):
        if b <= a: add("ascending", f"{vb.chapter_time(b)} {tb!r} does not come after {vb.chapter_time(a)}")
        elif b - a < CHAPTER_MIN_SECONDS: add("length", f"{vb.chapter_time(a)} {ta!r} is {b - a} s long")
    if ch and total is not None:
        if ch[-1][0] >= total: add("end", f"the last chapter starts at {vb.chapter_time(ch[-1][0])}, the video ends at {vb.chapter_time(total)}")
        elif total - ch[-1][0] < CHAPTER_MIN_SECONDS: add("length", f"the last chapter {ch[-1][1]!r} is {total - ch[-1][0]:.1f} s long")
    for t, title in ch:
        if not title: add("title", f"{vb.chapter_time(t)} has no title")
        elif len(title) >= CHAPTER_TITLE_MAX: add("title", f"{vb.chapter_time(t)}: title of {len(title)} characters")
    return bad


def parse_silences(log):
    """ffmpeg silencedetect output -> [(start, end)].  A silence that runs to the end of the file has no end line: None."""
    out, start = [], None
    for m in re.finditer(r"silence_(start|end):\s*(-?[\d.]+)", log):
        if m.group(1) == "start":
            if start is not None: out.append((start, None))
            start = max(0.0, float(m.group(2)))
        else:
            out.append((start if start is not None else 0.0, float(m.group(2)))); start = None
    if start is not None: out.append((start, None))
    return out


def expected_quiet(beats, starts, total, lead):
    """The stretches the storyboard says are silent -> [(start, end, why)]: the lead-in picture and every hold beat."""
    out = [(0.0, lead, "lead-in (thumbnail or title card)")]
    for k, b in enumerate(beats):
        if b.get("type") != "narration":
            end = starts[k + 1] if k + 1 < len(starts) else total
            out.append((starts[k], end, f"hold of beat {b.get('i', k)}: {b.get('why') or 'hold'}" + (f" in {b['section']}" if b.get("section") else "")))
    return out


def overlap(a0, a1, spans):
    """Length of [a0, a1] covered by the union of spans [(s, e), ...]."""
    got, pos = 0.0, a0
    for s, e in sorted(spans):
        s, e = max(s, pos), min(e, a1)
        if e > s:
            got += e - s; pos = e
    return got


def explain_silences(silences, quiet, total, margin=SILENCE_MARGIN, shortest=SILENCE_LIST):
    """Every silence of at least `shortest` seconds with the part of it that no expected silence explains.
    -> [{"start", "end", "seconds", "unexplained", "why": [str]}]"""
    out = []
    wide = [(s - margin, e + margin) for s, e, _ in quiet]
    for s, e in silences:
        e = total if e is None else e
        if e - s < shortest: continue
        why = [w for (qs, qe, w) in quiet if min(e, qe + margin) > max(s, qs - margin)]
        out.append({"start": round(s, 2), "end": round(e, 2), "seconds": round(e - s, 2),
                    "unexplained": round(max(0.0, (e - s) - overlap(s, e, wide)), 2), "why": why})
    return out


def parse_metadata(text):
    """video/youtube-metadata.md -> {"V001": {"title": str or None, "description": str or None}, ...}"""
    out = {}
    for m in re.finditer(r"^### (V\d{3})[^\n]*\n(.*?)(?=^### |^## |\Z)", text, re.S | re.M):
        body = m.group(2)
        pick = lambda label: (re.search(label + r":\s*\n+```[a-z]*\n(.*?)\n```", body, re.S) or [None, None])[1]
        out[m.group(1)] = {"title": pick("Title"), "description": pick("Description")}
    return out


def image_size(path):
    """-> (format, width, height) of a PNG or JPEG, read from the file header; (None, 0, 0) for anything else."""
    with open(path, "rb") as f:
        head = f.read(32)
        if head[:8] == b"\x89PNG\r\n\x1a\n" and head[12:16] == b"IHDR":
            return ("PNG",) + struct.unpack(">II", head[16:24])
        if head[:2] == b"\xff\xd8":
            f.seek(2)
            while True:
                b = f.read(4)
                if len(b) < 4 or b[0] != 0xFF: break
                kind, n = b[1], struct.unpack(">H", b[2:4])[0]
                if kind in (0xC0, 0xC1, 0xC2):
                    d = f.read(5)
                    h, w = struct.unpack(">HH", d[1:5])
                    return ("JPG", w, h)
                f.seek(n - 2, 1)
    return (None, 0, 0)


def norm_text(s):
    return re.sub(r"\s+", " ", s).strip()


def srt_coverage(cues, beats):
    """How much of the narration (beat by beat, in order) is found in the joined cue text -> (percent, [missing beat numbers])."""
    joined = norm_text(" ".join(" ".join(c["lines"]) for c in cues))
    pos, have, total, missing = 0, 0, 0, []
    for b in beats:
        if b.get("type") != "narration": continue
        t = norm_text(b.get("text", ""))
        if not t: continue
        total += len(t)
        at = joined.find(t, pos)
        if at < 0: missing.append(b.get("i"))
        else: have += len(t); pos = at + len(t)
    return (100.0 * have / total if total else 100.0), missing


def frame_detail(frame, w=FRAME_W, h=FRAME_H):
    """One grey frame (bytes) -> (% of pixels that are an edge to their right neighbour, mean brightness 0..255)."""
    edges = 0
    for y in range(h):
        row = frame[y * w:(y + 1) * w]
        edges += sum(1 for a, b in zip(row, row[1:]) if a - b > EDGE_STEP or b - a > EDGE_STEP)
    return 100.0 * edges / (w * h), sum(frame) / len(frame)


# ---- measuring ---------------------------------------------------------------------------------------------------------
def ff_run(cmd, timeout=FF_TIMEOUT, binary=False):
    """One analysis at low priority -> (stdout, stderr, problem or None)."""
    r = None
    for limit in (timeout, 2 * timeout):
        try:
            r = subprocess.run(["nice", "-n", "10"] + [str(c) for c in cmd], capture_output=True, timeout=limit); break
        except subprocess.TimeoutExpired:
            continue
    if r is None:
        return (b"" if binary else ""), "", f"{UNFINISHED} within {2 * timeout} s (the machine is busy): not measured, check again"
    out = r.stdout if binary else r.stdout.decode("utf-8", "replace")
    return out, r.stderr.decode("utf-8", "replace"), (None if r.returncode == 0 else f"exit code {r.returncode}")


UNFINISHED = "the analysis did not finish"


def error_lines(log):
    return [l.strip()[:200] for l in log.splitlines() if re.search(r"\[(error|fatal|panic)\]", l)]


def loudness_target():
    """The builder's own target, read from loudnorm() in tools/video_build.py -> (LUFS, dBTP, where it came from)."""
    try:
        m = re.search(r"I=(-?[\d.]+):TP=(-?[\d.]+)", inspect.getsource(vb.loudnorm))
        return float(m.group(1)), float(m.group(2)), "tools/video_build.py, loudnorm()"
    except Exception:
        return LOUDNESS_FALLBACK + ("fallback constant in tools/video_qc.py (the builder's target was not found)",)


class Report:
    def __init__(self, vid):
        self.vid, self.items = vid, []

    def add(self, id_, name, result, measured=None, threshold=None, detail=None, listing=None):
        """result: True / False, or "warn", or None for 'could not be checked here' (N/A)."""
        res = {True: "PASS", False: "FAIL", "warn": "WARN", None: "N/A"}[result]
        it = {"id": id_, "group": GROUPS[id_[0]], "name": name, "result": res}
        if measured is not None: it["measured"] = measured
        if threshold is not None: it["threshold"] = threshold
        if detail: it["detail"] = detail
        if listing: it["list"] = listing
        self.items.append(it)
        return result is True


def check_file(R, ff, fp, mp4, build, deep):
    """A: container, streams, constant frame rate, faststart, decode errors, durations.  -> duration in seconds (or None)"""
    out, err, bad = ff_run([fp, "-v", "error", "-print_format", "json", "-show_streams", "-show_format", mp4], 60)
    try:
        j = json.loads(out)
        vs = [s for s in j["streams"] if s["codec_type"] == "video"]
        aus = [s for s in j["streams"] if s["codec_type"] == "audio"]
        v, a, fmt = vs[0], aus[0], j["format"]
    except Exception:
        R.add("A1", "container is MP4 with one video and one audio stream", False, detail=f"ffprobe could not read the file: {bad or err[:200]}")
        return None
    with open(mp4, "rb") as f: ftyp = f.read(12)
    R.add("A1", "container is MP4 with one video and one audio stream", "mp4" in fmt.get("format_name", "") and ftyp[4:8] == b"ftyp" and len(vs) == 1 and len(aus) == 1,
          measured={"format": fmt.get("format_name"), "brand": ftyp[8:12].decode("ascii", "replace"), "video_streams": len(vs), "audio_streams": len(aus),
                    "size_mb": round(int(fmt.get("size", 0)) / 1e6, 1), "bit_rate_kbps": round(int(fmt.get("bit_rate", 0)) / 1000)}, threshold="mp4; 1 video + 1 audio")
    R.add("A2", "video codec is H.264", v.get("codec_name") == "h264", measured={"codec": v.get("codec_name"), "profile": v.get("profile"), "level": v.get("level")}, threshold="h264")
    R.add("A3", "picture is 1920x1080 with square pixels", (v.get("width"), v.get("height")) == (W, H) and v.get("sample_aspect_ratio", "1:1") in ("1:1", "0:1"),
          measured=f"{v.get('width')}x{v.get('height')}, SAR {v.get('sample_aspect_ratio', 'not set')}", threshold=f"{W}x{H}, SAR 1:1")
    # constant frame rate: nominal rate, average rate, and the distance between every two frames
    num, den = (int(x) for x in v.get("avg_frame_rate", "0/1").split("/"))
    avg = num / den if den else 0.0
    pk, _, pbad = ff_run([fp, "-v", "error", "-select_streams", "v:0", "-show_entries", "packet=pts_time", "-of", "csv=p=0", mp4], 90)
    pts = sorted(float(x.split(",")[0]) for x in pk.split() if re.match(r"-?[\d.]+", x))
    gaps = [b - a for a, b in zip(pts, pts[1:])]
    off = [g for g in gaps if abs(g - 1 / FPS) > FRAME_TIME_TOL]
    worst = max((abs(g - 1 / FPS) for g in gaps), default=0.0)
    nb = int(v.get("nb_frames", 0))
    vdur, adur = float(v.get("duration", 0)), float(a.get("duration", 0))
    R.add("A4", "30 frames per second, constant", v.get("r_frame_rate") == f"{FPS}/1" and abs(avg - FPS) <= FPS_AVG_TOL and not off and not pbad and len(pts) == nb and abs(nb - vdur * FPS) <= 1,
          measured={"r_frame_rate": v.get("r_frame_rate"), "avg_frame_rate": round(avg, 5), "frames": nb, "frame_gaps_off_by_more_than_tolerance": len(off),
                    "frame_gaps_not_exactly_1/30": sum(1 for g in gaps if abs(g - 1 / FPS) > 1e-6), "worst_gap_error_ms": round(worst * 1000, 3)},
          threshold=f"r_frame_rate {FPS}/1; average within {FPS_AVG_TOL}; every frame within {FRAME_TIME_TOL * 1000:.0f} ms of its slot",
          detail=pbad and f"reading the frame times: {pbad}")
    R.add("A5", "pixel format yuv420p, progressive", v.get("pix_fmt") == "yuv420p" and v.get("field_order", "progressive") == "progressive",
          measured=f"{v.get('pix_fmt')}, {v.get('field_order', 'field order not set')}", threshold="yuv420p, progressive")
    R.add("A6", "audio is AAC at 48 kHz", a.get("codec_name") == "aac" and int(a.get("sample_rate", 0)) == vb.SR,
          measured={"codec": a.get("codec_name"), "profile": a.get("profile"), "sample_rate": int(a.get("sample_rate", 0)), "channels": a.get("channels"),
                    "bit_rate_kbps": round(int(a.get("bit_rate", 0)) / 1000)}, threshold=f"aac, {vb.SR} Hz")
    R.add("A7", "faststart: the index (moov) stands before the data (mdat)", bool(vb.is_faststart(mp4)), threshold="moov before mdat")
    # A8 is filled in by check_audio (the same pass decodes the whole audio stream)
    # A9: every packet of the file is read; then the picture is decoded (key frames, or every frame with --deep) in check_picture
    _, cerr, cbad = ff_run([ff, "-hide_banner", "-nostats", "-loglevel", "level+error", "-i", mp4, "-map", "0", "-c", "copy", "-f", "null", os.devnull])
    R._copy_errors = error_lines(cerr) + ([f"reading all packets: {cbad}"] if cbad else [])
    R.add("A10", "video and audio are equally long", abs(vdur - adur) <= AV_DUR_TOL, measured={"video_s": round(vdur, 3), "audio_s": round(adur, 3), "difference_s": round(abs(vdur - adur), 3)},
          threshold=f"difference at most {AV_DUR_TOL} s")
    dur = float(fmt.get("duration", max(vdur, adur)))
    if build and build.get("seconds") is not None:
        R.add("A11", "length equals the length the builder recorded", abs(dur - build["seconds"]) <= BUILD_DUR_TOL,
              measured={"file_s": round(dur, 3), "build_json_s": build["seconds"]}, threshold=f"difference at most {BUILD_DUR_TOL} s")
    else:
        R.add("A11", "length equals the length the builder recorded", None, detail="no .build.json")
    tags = (v.get("color_space"), v.get("color_primaries"), v.get("color_transfer"), v.get("color_range"))
    R.add("A12", "colour is tagged BT.709, limited range", True if (tags[0] == "bt709" and tags[3] == "tv") else "warn",
          measured=dict(zip(("space", "primaries", "transfer", "range"), tags)), threshold="colour space bt709, range tv (players guess when the tag is missing)")
    return dur


def check_audio(R, ff, mp4, dur, sb, build):
    """B: loudness, true peak, clipping, silences.  One pass decodes the whole audio stream (A8).  -> silences [(start, end)]"""
    af = (f"ebur128=peak=true:framelog=quiet,astats=measure_perchannel=none:measure_overall=Peak_level+Flat_factor+Peak_count,"
          f"silencedetect=noise={SILENCE_NOISE_DB}dB:d={SILENCE_MIN}")
    _, log, bad = ff_run([ff, "-hide_banner", "-nostats", "-loglevel", "level+info", "-i", mp4, "-vn", "-af", af, "-f", "null", os.devnull])
    errs = error_lines(log) + ([f"audio analysis: {bad}"] if bad else [])
    R.add("A8", "the whole audio stream decodes without an error", not errs, measured=f"{len(errs)} error line(s)", threshold="0", listing=errs[:20])
    tail = log[log.rfind("Summary:"):] if "Summary:" in log else ""
    num = lambda pat, src: (lambda m: float(m.group(1)) if m else None)(re.search(pat, src))
    i_lufs, lra, tp = num(r"\bI:\s+(-?[\d.]+) LUFS", tail), num(r"LRA:\s+(-?[\d.]+) LU", tail), num(r"Peak:\s+(-?[\d.]+) dBFS", tail)
    peak, flat = num(r"Peak level dB:\s+(-?[\d.]+)", log), num(r"Flat factor:\s+(-?[\d.]+)", log)
    tgt_i, tgt_tp, src = loudness_target()
    if bad and UNFINISHED in bad:
        for id_, name in (("B1", "integrated loudness at the builder's target"), ("B2", "true peak below the ceiling"), ("B3", "no clipping"), ("B4", "no silence that the storyboard does not explain")):
            R.add(id_, name, None, detail=bad)
        return None
    if i_lufs is None or tp is None:
        R.add("B1", "integrated loudness at the builder's target", False, detail="ffmpeg's ebur128 filter gave no result")
    else:
        R.add("B1", "integrated loudness at the builder's target", abs(i_lufs - tgt_i) <= LOUDNESS_WINDOW, measured={"integrated_lufs": i_lufs, "loudness_range_lu": lra},
              threshold=f"{tgt_i:g} LUFS +/- {LOUDNESS_WINDOW:g} LU (target from {src})")
        R.add("B2", "true peak below the ceiling", tp <= TRUE_PEAK_MAX, measured={"true_peak_dbtp": tp}, threshold=f"at most {TRUE_PEAK_MAX:g} dBTP (builder's target {tgt_tp:g})")
        R.add("B3", "no clipping", peak is not None and peak < CLIP_SAMPLE_PEAK and tp < 0 and not flat, measured={"sample_peak_dbfs": peak, "true_peak_dbtp": tp, "flat_factor": flat},
              threshold=f"sample peak below {CLIP_SAMPLE_PEAK:g} dBFS, true peak below 0 dBTP, no flat tops")
    silences = [(s, dur if e is None else e) for s, e in parse_silences(log)]
    starts = (build or {}).get("beat_starts")
    if not sb or not starts or len(starts) != len(sb["beats"]):
        R.add("B4", "no silence that the storyboard does not explain", None, measured={"silences_over_1s": sum(1 for s, e in silences if e - s >= SILENCE_LIST)},
              detail="needs the storyboard and the beat starts of .build.json, with the same number of beats")
        return silences
    quiet = expected_quiet(sb["beats"], starts, dur, vb.LEAD)
    found = explain_silences(silences, quiet, dur)
    fails = [x for x in found if x["unexplained"] > SILENCE_FAIL]
    warns = [x for x in found if SILENCE_WARN < x["unexplained"] <= SILENCE_FAIL]
    show = lambda x: f"{vb.chapter_time(x['start'])} to {vb.chapter_time(x['end'])} ({x['start']:.1f} to {x['end']:.1f} s): {x['seconds']:.1f} s silent, {x['unexplained']:.1f} s unexplained" + (f" [{beat_at(sb, starts, x['start'] + x['seconds'] / 2)}]")
    R.add("B4", "no silence that the storyboard does not explain", False if fails else ("warn" if warns else True),
          measured={"silences_over_1s": len(found), "longest_s": max((x["seconds"] for x in found), default=0), "longest_unexplained_s": max((x["unexplained"] for x in found), default=0),
                    "unexplained_over_warn": len(warns), "unexplained_over_fail": len(fails)},
          threshold=f"unexplained silence: warning above {SILENCE_WARN:g} s, failure above {SILENCE_FAIL:g} s (level {SILENCE_NOISE_DB} dB; holds and the lead-in explain themselves and {SILENCE_MARGIN:g} s around them)",
          listing=[show(x) for x in fails + warns])
    R._silences_found = found
    return silences


def beat_at(sb, starts, t):
    k = max((i for i, s in enumerate(starts) if s <= t), default=0)
    b = sb["beats"][k]
    return f"beat {b.get('i', k)}, {b.get('section', '')}, {b.get('type')}" + (f": {norm_text(b.get('text', ''))[:70]!r}" if b.get("text") else "")


def check_narration(R, sb, build, dur, silences):
    """C: pace of every beat, the verified mark of every voice clip, raw symbols and emoji in the spoken text, holds are silent."""
    starts = (build or {}).get("beat_starts")
    if not sb or not build or not starts:
        for id_, name in (("C1", "pace of every narration beat"), ("C2", "every voice clip is a verified one"), ("C3", "no raw code symbol and no emoji reaches the voice"),
                          ("C4", "the sound follows the beat timeline")):
            R.add(id_, name, None, detail="needs the storyboard and .build.json")
        return
    beats = sb["beats"]
    same = len(starts) == len(beats)
    audio = build.get("audio") or {}
    ai = audio.get("mode") == "draft"
    voice, rate = audio.get("voice"), audio.get("rate")
    chunks = {b["i"]: vb.spoken_chunks(sb, b) for b in beats if b["type"] == "narration"}
    # C3: what the voice is given (the builder's own text preparation), searched with the builder's own list of raw symbols
    raw, emo = [], []
    for b in beats:
        if b["type"] != "narration": continue
        said = " ".join(c for c in chunks[b["i"]] if isinstance(c, str))
        left = sorted(set(re.findall(vb.RAW_SYMBOL, said.replace(vb.PAUSE, " "))))
        if left: raw.append(f"beat {b['i']} ({b['section']}): {' '.join(repr(x.strip() or x) for x in left)} in {excerpt(said, vb.RAW_SYMBOL)!r}")
        e = sorted(set(EMOJI.findall(said)))
        if e: emo.append(f"beat {b['i']} ({b['section']}): {' '.join(f'U+{ord(x):04X}' for x in e)} in {said[:80]!r}")
    R.add("C3", "no raw code symbol and no emoji reaches the voice", not raw and not emo, measured={"beats_with_raw_symbol": len(raw), "beats_with_emoji": len(emo)},
          threshold="0 and 0 (symbols: RAW_SYMBOL of tools/video_build.py)", listing=raw + emo)
    if not same:
        msg = f"the storyboard has {len(beats)} beats, .build.json has {len(starts)} beat starts: the video was built from another storyboard"
        R.add("C1", "pace of every narration beat", False, detail=msg)
        R.add("C2", "every voice clip is a verified one", False, detail=msg)
        R.add("C4", "the sound follows the beat timeline", False, detail=msg)
        return
    total = build.get("seconds") or dur
    durs = [(starts[k + 1] if k + 1 < len(starts) else total) - starts[k] for k in range(len(starts))]
    # C1: words per second of every beat
    nominal = (rate or WPM) / 60.0
    lo, hi = (PACE_FACTOR[0] * nominal, PACE_FACTOR[1] * nominal) if ai else PACE_HUMAN_WPS
    flagged, judged, vals, c1_beats, c1_three = [], 0, [], set(), []
    clip_state = {}
    def clip_fault(c):
        """The builder's own judgement of one cached clip, with its .ok mark -> (fault, words/s, letters/s, pace fault the mark excuses, accepted by three identical takes)"""
        if c not in clip_state:
            cp = vb.tts_path(c, voice, rate)
            clip_state[c] = vb.clip_fault(c, cp, rate) + (vb.clip_mark(cp)[1],)
        return clip_state[c]
    for b, d in zip(beats, durs):
        if b["type"] != "narration": continue
        cs = chunks[b["i"]]
        words = sum(len(c.split()) for c in cs if isinstance(c, str)) if ai else len(b["text"].split())
        speech = d - (vb.DRAFT_GAP + sum(c for c in cs if not isinstance(c, str)) if ai else 0.0)
        wps = words / speech if speech > 0.05 else 99.0
        said = " ".join(c for c in cs if isinstance(c, str)) if ai else b["text"]
        lps = (len(re.findall(r"[^\W\d_]", said)) + 4 * len(re.findall(r"\d", said))) / speech if speech > 0.05 else 999.0
        if ai:                                               # the computer voice: exactly the rule the builder applies to every clip
            fault = vb.pace_fault(said, speech, rate or WPM)[0] if speech > 0.05 else "fast"
            if words >= PACE_MIN_WORDS: judged += 1; vals.append(wps)
            if fault and not vb.pace_wide_fault(said, speech, rate or WPM) and \
                    any(clip_fault(c)[4] and not clip_fault(c)[0] for c in cs if isinstance(c, str) and vb.tts_path(c, voice, rate).exists()):
                # outside the bounds, but made from a clip that came three times with this length (its .ok mark says so): a warning
                c1_three.append(f"beat {b['i']} at {vb.chapter_time(starts[b['i']])} ({b['section']}): {'faster' if fault == 'fast' else 'slower'} than the bounds, accepted because three takes had this length; listen to it: "
                                f"{wps:.2f} words/s, {lps:.1f} letters/s ({words} words in {speech:.2f} s): {norm_text(b['text'])[:110]!r}")
            elif fault:
                c1_beats.add(b["i"])
                flagged.append(f"beat {b['i']} at {vb.chapter_time(starts[b['i']])} ({b['section']}): {'too fast (cut short?)' if fault == 'fast' else 'too slow (silence inside?)'}: "
                               f"{wps:.2f} words/s, {lps:.1f} letters/s ({words} words in {speech:.2f} s): {norm_text(b['text'])[:110]!r}")
            continue
        if words >= PACE_MIN_WORDS:
            judged += 1; vals.append(wps)
            if not lo <= wps <= hi or (ai and not PACE_LETTERS[0] <= lps <= PACE_LETTERS[1]):
                flagged.append(f"beat {b['i']} at {vb.chapter_time(starts[b['i']])} ({b['section']}): {'too fast (cut short?)' if wps > hi or lps > PACE_LETTERS[1] else 'too slow (silence inside?)'}: "
                               f"{wps:.2f} words/s, {lps:.1f} letters/s ({words} words in {speech:.2f} s): {norm_text(b['text'])[:110]!r}")
        elif wps > PACE_FLOOR_WPS:                           # (a recorded narration; the computer voice was judged above, by the builder's rule)
            flagged.append(f"beat {b['i']} at {vb.chapter_time(starts[b['i']])} ({b['section']}): too fast (cut short?): {words} word(s) in {speech:.2f} s: {norm_text(b['text'])[:110]!r}")
    vals.sort()
    R.add("C1", "pace of every narration beat", False if flagged else ("warn" if c1_three else True),
          measured={"beats_judged": judged, "beats_outside": len(flagged), "beats_outside_accepted_by_three_identical_takes": len(c1_three), "slowest_wps": round(vals[0], 2) if vals else None, "median_wps": round(vals[len(vals) // 2], 2) if vals else None,
                    "fastest_wps": round(vals[-1], 2) if vals else None, "voice": voice, "rate_wpm": rate},
          threshold=f"{lo:.2f} to {hi:.2f} words/s and {PACE_LETTERS[0]:g} to {PACE_LETTERS[1]:g} letters/s for beats of {PACE_MIN_WORDS} words or more; shorter beats: " + (f"at most {PACE_SHORT_FAST[0]:g} words/s and {PACE_SHORT_FAST[1]:g} letters/s, and not under both {PACE_SHORT_SLOW[0]:g} words/s and {PACE_SHORT_SLOW[1]:g} letters/s" if ai else f"never above {PACE_FLOOR_WPS:g} words/s") + ". " + f"A beat outside whose clip came {vb.SAME_TAKES} times with one length (its .ok mark) and is within {PACE_WIDE:g} times these bounds is a warning: listen to it", listing=flagged + c1_three)
    # C2: the clips of the voice cache this video was made from
    tdir = vb.tts_path("", voice, rate).parent
    if not ai:
        R.add("C2", "every voice clip is a verified one", None, detail="recorded narration: there are no voice clips")
    elif not tdir.is_dir() or not any(tdir.glob("*.wav")):
        R.add("C2", "every voice clip is a verified one", None, detail="the voice cache video/production/.cache/tts/ is gone: the marks cannot be read")
    else:
        built_at = build.get("_mtime", 0)
        n = gone = unmarked = late = 0
        bad, differ, secs, pace, three = [], [], {}, [], []
        for b, d in zip(beats, durs):
            if b["type"] != "narration": continue
            cs, want, known = chunks[b["i"]], vb.DRAFT_GAP, True
            for k, c in enumerate(cs):
                if not isinstance(c, str):
                    want += c; continue
                n += 1
                p = vb.tts_path(c, voice, rate)
                ok = p.with_suffix(".ok")
                if not p.exists():
                    gone += 1; known = False; continue
                if not ok.exists():
                    unmarked += 1; bad.append(f"beat {b['i']} ({b['section']}): no .ok mark for {c[:80]!r}")
                elif ok.stat().st_mtime > built_at + 1:
                    late += 1; bad.append(f"beat {b['i']} ({b['section']}): verified only after this video was built: {c[:80]!r}")
                key = (str(p), k == len(cs) - 1)
                if key not in secs:
                    try: secs[key] = len(vb.trim_voice(vb.read_wav(p), 2400 if key[1] else 960)) / vb.SR
                    except Exception: secs[key] = None
                if secs[key] is None: known = False
                else: want += secs[key]
                if ok.exists():                              # the mark says "verified"; the pace bounds must agree, or it is not
                    fault, cw, cl, excused, is_three = clip_fault(c)
                    if not fault and is_three:               # accepted by three identical takes (the clip itself, or a part it was joined from)
                        three.append(f"beat {b['i']} at {vb.chapter_time(starts[b['i']])} ({b['section']}): accepted because three takes had this length, "
                                     + (f"{'faster' if excused == 'fast' else 'slower'} than the pace bounds" if excused else "a part of it outside the pace bounds")
                                     + f"; listen to it: {cw:.2f} words/s, {cl:.1f} letters/s: {c[:80]!r}")
                    if fault: pace.append(f"beat {b['i']} ({b['section']}): marked verified, but {'too short' if fault == 'fast' else 'too long' if fault == 'slow' else fault} for its words: {c[:80]!r}")
            if b["i"] in c1_beats:
                pace.append(f"beat {b['i']} ({b['section']}): fails the pace check C1, so its clips cannot count as verified")
            if known and abs(want - d) > CLIP_LEN_TOL:
                differ.append(f"beat {b['i']} at {vb.chapter_time(starts[b['i']])} ({b['section']}): {d:.2f} s in the video, {want:.2f} s from the clips now in the cache: {norm_text(b['text'])[:80]!r}")
        res = False if (unmarked or late or differ or pace) else ("warn" if gone or three else True)
        R.add("C2", "every voice clip is a verified one", res,
              measured={"clips": n, "verified_before_the_build": n - gone - unmarked - late, "without_mark": unmarked, "verified_after_the_build": late, "not_in_cache_any_more": gone,
                        "beats_whose_length_differs_from_the_cached_clips": len(differ), "outside_the_pace_bounds": len(pace), "accepted_by_three_identical_takes": len(three)},
              threshold=f"every clip has its .ok mark, made before the build, and is inside the pace bounds of C1; no beat fails C1; every beat is as long as its cached clips (within {CLIP_LEN_TOL:g} s). A clip that left the cache is a warning, and so is a clip outside the pace bounds that its mark says came {vb.SAME_TAKES} times with one length (within {PACE_WIDE:g} times the bounds): listen to it",
              listing=pace + differ + bad + three)
    # C4: the sound track is silent where the timeline has a hold: narration and picture share one clock
    if silences is None:
        R.add("C4", "the sound follows the beat timeline", None, detail="the audio analysis did not finish")
        return
    holds, loud = 0, []
    for b, s, d in zip(beats, starts, durs):
        if b["type"] == "narration" or d < HOLD_MIN: continue
        holds += 1
        share = overlap(s, s + d, silences) / d
        if share < HOLD_SILENT_SHARE:
            loud.append(f"hold of beat {b['i']} at {vb.chapter_time(s)} ({b['section']}, {b.get('why')}): {d:.1f} s long, silent for {share * 100:.0f} %")
    mono = all(b2 >= b1 for b1, b2 in zip(starts, starts[1:])) and abs(starts[0] - vb.LEAD) < 0.02 and starts[-1] < total
    R.add("C4", "the sound follows the beat timeline", mono and not loud, measured={"beats": len(beats), "holds_checked": holds, "holds_with_sound": len(loud), "beat_starts_ascending": mono},
          threshold=f"beat starts ascend from {vb.LEAD:g} s; every hold of {HOLD_MIN:g} s or more is silent for at least {HOLD_SILENT_SHARE * 100:.0f} % of its length", listing=loud)


def excerpt(text, pattern, width=40):
    m = re.search(pattern, text)
    return text[max(0, m.start() - width):m.end() + width] if m else text[:2 * width]


def check_picture(R, ff, mp4, dur, deep):
    """D: black stretches and blank sampled frames.  The same pass decodes the picture (A9)."""
    fc = (f"[0:v]split[a][b];[a]blackdetect=d={BLACK_MIN}:pic_th={BLACK_PIC_TH}:pix_th={BLACK_PIX_TH}[bo];"
          f"[b]fps=1/{FRAME_EVERY},scale={FRAME_W}:{FRAME_H},format=gray[so]")
    cmd = [ff, "-hide_banner", "-nostats", "-loglevel", "level+info"] + ([] if deep else ["-skip_frame", "nokey"]) + ["-threads", "2", "-i", mp4, "-an",
           "-filter_complex", fc, "-map", "[bo]", "-f", "null", os.devnull, "-map", "[so]", "-f", "rawvideo", "pipe:1"]
    raw, log, bad = ff_run(cmd, timeout=FF_TIMEOUT if not deep else 3 * FF_TIMEOUT, binary=True)
    errs = getattr(R, "_copy_errors", []) + error_lines(log) + ([f"decoding the picture: {bad}"] if bad else [])
    m = re.findall(r"frame=\s*(\d+)", log)
    R.add("A9", "the video stream is intact", not errs, measured={"error_lines": len(errs), "decoded": "every frame" if deep else "every packet read, key frames decoded", "frames_decoded": int(m[-1]) if m else None},
          threshold="0 errors", listing=errs[:20])
    black = [(float(a), float(b)) for a, b in re.findall(r"black_start:(-?[\d.]+) black_end:(-?[\d.]+)", log)]
    if bad and UNFINISHED in bad:
        R.add("D1", "no black stretch", None, detail=bad); R.add("D2", "no blank frame among the sampled frames", None, detail=bad)
        return
    R.add("D1", "no black stretch", not black and not bad, measured={"black_stretches": len(black), "frames_examined": "all" if deep else "key frames"},
          threshold=f"none of {BLACK_MIN:g} s or more" + ("" if deep else " (key frames only: a black stretch between two key frames is not seen; --deep examines every frame)"),
          listing=[f"{vb.chapter_time(a)} to {vb.chapter_time(b)} ({a:.2f} to {b:.2f} s)" for a, b in black])
    size = FRAME_W * FRAME_H
    n = len(raw) // size
    blank, least = [], None
    for k in range(n):
        d, mean = frame_detail(raw[k * size:(k + 1) * size])
        least = d if least is None else min(least, d)
        if d < FRAME_MIN_DETAIL:
            blank.append(f"frame near {vb.chapter_time(k * FRAME_EVERY)} ({k * FRAME_EVERY} s): {d:.2f} % detail, mean brightness {mean:.0f} of 255")
    want = int(dur // FRAME_EVERY) + 1 if dur else 0
    R.add("D2", "no blank frame among the sampled frames", n > 0 and not blank and n >= want - 1, measured={"frames_sampled": n, "expected": want, "blank": len(blank), "least_detail_percent": None if least is None else round(least, 2)},
          threshold=f"one frame every {FRAME_EVERY} s; each has at least {FRAME_MIN_DETAIL:g} % edge pixels", listing=blank)


def check_subtitles(R, srt, dur, sb, build):
    if not srt.exists():
        R.add("E1", "subtitle file parses", False, detail=f"{srt.name} is missing")
        return
    cues, problems = parse_srt(srt.read_text(encoding="utf-8", errors="replace"))
    want = (build or {}).get("subtitle_cues")
    if want is not None and want != len(cues): problems.append(f"{len(cues)} cues in the file, .build.json says {want}")
    R.add("E1", "subtitle file parses", bool(cues) and not problems, measured={"cues": len(cues)}, threshold="every block has a number, a time line and text; numbers run 1, 2, 3; count as in .build.json", listing=problems[:20])
    if not cues: return
    t = lambda x: vb.srt_time(x)
    order = [f"cue {c['n']}: ends before it starts ({t(c['start'])} --> {t(c['end'])})" for c in cues if c["end"] <= c["start"]]
    order += [f"cue {b['n']} starts at {t(b['start'])}, before cue {a['n']} ends at {t(a['end'])}" for a, b in zip(cues, cues[1:]) if b["start"] < a["end"] or b["start"] < a["start"]]
    R.add("E2", "cues ascend and do not overlap", not order, measured=f"{len(order)} problem(s)", threshold="0", listing=order[:40])
    R.add("E3", "cues lie inside the video", cues[0]["start"] >= 0 and (dur is None or max(c["end"] for c in cues) <= dur + SRT_TAIL_TOL),
          measured={"first_start_s": cues[0]["start"], "last_end_s": max(c["end"] for c in cues), "video_s": dur and round(dur, 3)}, threshold=f"first cue at 0 or later; last end at most {SRT_TAIL_TOL:g} s after the video")
    empty = [f"cue {c['n']} at {t(c['start'])}" for c in cues if not norm_text(" ".join(c["lines"]))]
    R.add("E4", "no empty cue", not empty, measured=f"{len(empty)} empty", threshold="0", listing=empty[:40])
    long_ = [f"cue {c['n']} at {t(c['start'])}: {len(c['lines'])} lines, longest {max(len(l) for l in c['lines'])} characters: {max(c['lines'], key=len)!r}"
             for c in cues if c["lines"] and (len(c["lines"]) > SRT_LINES_MAX or max(len(l) for l in c["lines"]) > SRT_LINE_MAX)]
    R.add("E5", "lines are short enough to read", "warn" if long_ else True, measured={"cues_too_long": len(long_), "longest_line": max((len(l) for c in cues for l in c["lines"]), default=0), "most_lines": max(len(c["lines"]) for c in cues)},
          threshold=f"at most {SRT_LINES_MAX} lines of at most {SRT_LINE_MAX} characters (warning)", listing=long_)
    cps = [(len(norm_text(" ".join(c["lines"]))) / max(0.001, c["end"] - c["start"]), c) for c in cues]
    fast = [f"cue {c['n']} at {t(c['start'])}: {v:.1f} characters/s ({len(norm_text(' '.join(c['lines'])))} in {c['end'] - c['start']:.2f} s): {norm_text(' '.join(c['lines']))[:70]!r}" for v, c in cps if v > SRT_CPS_MAX]
    R.add("E6", "reading speed", "warn" if fast else True, measured={"cues_too_fast": len(fast), "fastest_cps": round(max(v for v, _ in cps), 1), "median_cps": round(sorted(v for v, _ in cps)[len(cps) // 2], 1)},
          threshold=f"at most {SRT_CPS_MAX:g} characters per second (warning)", listing=fast)
    tags = []
    for c in cues:
        text = "\n".join(c["lines"])
        hit = [name for name, pat in SRT_FORBIDDEN if re.search(pat, text)]
        if hit: tags.append(f"cue {c['n']} at {t(c['start'])}: {', '.join(hit)} in {norm_text(text)[:80]!r}")
    R.add("E7", "no tag and no stage direction in the cue text", not tags, measured=f"{len(tags)} cue(s)", threshold="0: " + ", ".join(n for n, _ in SRT_FORBIDDEN), listing=tags)
    if sb:
        pct, missing = srt_coverage(cues, sb["beats"])
        R.add("E8", "the cues carry the whole narration", pct >= SRT_MIN_COVERAGE, measured={"coverage_percent": round(pct, 2), "beats_not_found": len(missing)},
              threshold=f"at least {SRT_MIN_COVERAGE:g} % of the storyboard's narration, beat by beat and in order", listing=[f"beat {i} is not in the subtitles (or not in order)" for i in missing[:40]])
    else:
        R.add("E8", "the cues carry the whole narration", None, detail="no storyboard")


def check_chapters(R, chap, dur, build):
    if not chap.exists():
        R.add("F1", "chapter list follows YouTube's rules", False, detail=f"{chap.name} is missing")
        return ""
    text = chap.read_text(encoding="utf-8", errors="replace")
    ch, problems = parse_chapters(text)
    bad = chapter_problems(ch, dur)
    names = {"first": ("F1", "first chapter starts at 0:00"), "count": ("F2", f"at least {CHAPTERS_MIN} chapters"), "ascending": ("F3", "chapters ascend"),
             "length": ("F4", f"every chapter is at least {CHAPTER_MIN_SECONDS} s long"), "end": ("F5", "the last chapter starts before the end"),
             "title": ("F6", f"every chapter has a title under {CHAPTER_TITLE_MAX} characters")}
    want = (build or {}).get("chapters")
    for rule, (id_, name) in names.items():
        extra = (problems + ([f"{len(ch)} chapters in the file, .build.json says {want}"] if want is not None and want != len(ch) else [])) if rule == "first" else []
        gaps = [b - a for (a, _), (b, _) in zip(ch, ch[1:])] + ([dur - ch[-1][0]] if ch and dur else [])
        measured = {"first": ch[0][0] if ch else None, "count": len(ch), "length": round(min(gaps), 1) if gaps else None, "end": ch[-1][0] if ch else None,
                    "title": max((len(t) for _, t in ch), default=0)}.get(rule)
        R.add(id_, name, not bad.get(rule) and not extra, measured=measured, listing=(bad.get(rule, []) + extra)[:20])
    return text


def check_thumbnail(R, vid):
    hits = [p for p in (THUMBS / f"{vid}.png", THUMBS / f"{vid}.jpg", THUMBS / f"{vid}.jpeg") if p.exists()]
    if not hits:
        R.add("G1", "thumbnail exists, PNG or JPG", False, detail=f"video/thumbnails/{vid}.png is missing")
        return
    kind, w, h = image_size(hits[0])
    size = hits[0].stat().st_size
    R.add("G1", "thumbnail exists, PNG or JPG", kind in ("PNG", "JPG"), measured=f"{hits[0].name}: {kind or 'not a PNG or JPG'}", threshold="PNG or JPG (by content, not by name)")
    R.add("G2", "thumbnail is 1280x720", (w, h) == THUMB_SIZE, measured=f"{w}x{h}", threshold="1280x720")
    R.add("G3", "thumbnail is under 2 MB", size < THUMB_MAX_BYTES, measured=f"{size / 1e6:.2f} MB", threshold="under 2 MB (YouTube's limit)")


_META = {}


def check_metadata(R, vid, chapters_text):
    p = VIDEO / "youtube-metadata.md"
    if "all" not in _META:
        _META["all"] = parse_metadata(p.read_text(encoding="utf-8")) if p.exists() else None
    meta = _META["all"]
    e = (meta or {}).get(vid)
    if not e or not e["title"] or e["description"] is None:
        R.add("F7", "title and description in youtube-metadata.md", False, detail="no file" if meta is None else ("no entry" if not e else "the entry has no title block or no description block"))
        return
    full = len(e["description"]) + (2 + len(chapters_text.strip()) if chapters_text.strip() else 0)
    R.add("F7", "title and description in youtube-metadata.md", 0 < len(e["title"]) <= YT_TITLE_MAX and 0 < len(e["description"]) and full <= YT_DESC_MAX,
          measured={"title_chars": len(e["title"]), "description_chars": len(e["description"]), "description_with_chapters_chars": full},
          threshold=f"title 1 to {YT_TITLE_MAX} characters; description with the chapter list pasted below it at most {YT_DESC_MAX}")
    angle = [k for k in ("title", "description") if re.search(r"[<>]", e[k])]
    R.add("F8", "no angle bracket in title or description", "warn" if angle else True, measured=", ".join(angle) or "none",
          threshold="YouTube rejects < and > in titles and descriptions (warning: check by hand before upload)")


def check_build(R, vid, mp4, build, rep, sb):
    """I: the files belong together and the build is current."""
    if not build:
        R.add("I1", "the build report belongs to this MP4", False, detail=f"{rep.name} is missing or unreadable")
        for id_, name in (("I2", "the video was built from the script as it is now"), ("I5", "built with the animation layer"), ("I6", "narration from after the voice fix")):
            R.add(id_, name, None, detail="no .build.json")
    else:
        st = mp4.stat()
        dt = build["_mtime"] - st.st_mtime
        size = (build.get("probe") or {}).get("size_bytes")
        R.add("I1", "the build report belongs to this MP4", size == st.st_size and -1 <= dt <= REPORT_AFTER_MP4_MAX and build.get("id") == vid and build.get("checks_passed") is True,
              measured={"mp4_bytes": st.st_size, "build_json_bytes": size, "report_written_after_mp4_s": round(dt, 1), "builder_checks_passed": build.get("checks_passed"), "build_version": build.get("build_version")},
              threshold=f"same size in bytes; report written 0 to {REPORT_AFTER_MP4_MAX} s after the MP4; the builder's own checks passed")
        sp = script_path(vid)
        now = sha1(sp.read_text(encoding="utf-8")) if sp else None
        R.add("I2", "the video was built from the script as it is now", now is not None and build.get("script_sha1") == now,
              measured={"script_now": now and now[:12], "build_json": (build.get("script_sha1") or "")[:12]}, threshold="equal SHA-1")
        R.add("I5", "built with the animation layer", build.get("animated") is True, measured={"animated": build.get("animated"), **{k: v for k, v in (build.get("animation") or {}).items() if k in ("clips", "segments")}}, threshold="animated: true")
        began = build["_mtime"] - float(build.get("built_in_seconds") or 0)
        stamp = lambda x: datetime.datetime.fromtimestamp(x).strftime("%Y-%m-%d %H:%M:%S")
        ai = (build.get("audio") or {}).get("mode") == "draft"
        R.add("I6", "narration from after the voice fix", (began >= VOICE_FIX_EPOCH) if ai else None,
              measured={"build_started": stamp(began), "build_finished": stamp(build["_mtime"]), "voice_fix": stamp(VOICE_FIX_EPOCH), "builder_modified_now": stamp((ROOT / "tools" / "video_build.py").stat().st_mtime)},
              threshold="the build started after the voice fix", detail=None if not ai else (None if began >= VOICE_FIX_EPOCH else "narration from before the voice fix: build the voice again (make.sh voice)"))
    if not sb:
        R.add("I3", "the storyboard is the one for this script", False, detail="no storyboard")
        R.add("I4", "the storyboard has no warnings and no hints", None, detail="no storyboard")
        return
    sp = script_path(vid)
    now = sha1(sp.read_text(encoding="utf-8")) if sp else None
    newer = build and (STORYBOARDS / f"{vid}.json").stat().st_mtime > build["_mtime"] + 1
    ok = now is not None and sb.get("script_sha1") == now and sb.get("id") == vid and (not sp or sb.get("script") == rel(sp)) and (not build or sb.get("script_sha1") == build.get("script_sha1"))
    R.add("I3", "the storyboard is the one for this script", (("warn" if newer else True) if ok else False),
          measured={"storyboard_script": (sb.get("script_sha1") or "")[:12], "script_now": now and now[:12], "storyboard_version": sb.get("version"), "storyboard_written_after_the_build": bool(newer)},
          threshold="storyboard, script on disk and .build.json name the same script SHA-1 (warning if the storyboard file is newer than the build)")
    notes = [f"warning: {w}" for w in sb.get("warnings", [])] + [f"hint: {h}" for h in sb.get("hints", [])]
    R.add("I4", "the storyboard has no warnings and no hints", not notes, measured={"warnings": len(sb.get("warnings", [])), "hints": len(sb.get("hints", []))}, threshold="0 and 0", listing=notes)


def check_spoken_log(R, vid, sb, build):
    """C5: the text the builder sent to the voice for the last build, against what it would send today."""
    p = CACHE / "tts" / f"{vid}.spoken.txt"
    if not sb or not build or not p.exists() or (build.get("audio") or {}).get("mode") != "draft":
        R.add("C5", "the spoken text has not changed since the build", None, detail="no record of the spoken text (video/production/.cache/tts/VNNN.spoken.txt)")
        return
    began = build["_mtime"] - float(build.get("built_in_seconds") or 0)
    if not began - 5 <= p.stat().st_mtime <= build["_mtime"] + 5:
        R.add("C5", "the spoken text has not changed since the build", None, detail="the record of the spoken text is not from this build (another build wrote it since, or is writing it now)")
        return
    then = {}
    for line in p.read_text(encoding="utf-8").splitlines():
        m = re.match(r"\s*(\d+)  (.*)$", line)
        if m: then[int(m.group(1))] = m.group(2)
    diff = []
    for b in sb["beats"]:
        if b["type"] != "narration": continue
        now = " ".join(c if isinstance(c, str) else f"[{c:.2f} s]" for c in vb.spoken_chunks(sb, b))
        was = then.get(b["i"])
        if was != now:
            k = next((j for j, (x, y) in enumerate(zip(was or "", now)) if x != y), min(len(was or ""), len(now)))     # where the two texts part
            a = max(0, k - 30)
            diff.append(f"beat {b['i']} ({b['section']}): the video says {'(nothing)' if was is None else was[a:k + 40]!r}, today it would say {now[a:k + 40]!r}")
    R.add("C5", "the spoken text has not changed since the build", not diff, measured=f"{len(diff)} beat(s) differ", threshold="0", listing=diff)


# ---- one video ---------------------------------------------------------------------------------------------------------
def file_id(p):
    st = p.stat()
    return {"bytes": st.st_size, "mtime": round(st.st_mtime, 3)}


def qc_one(vid, ff, fp, deep=False):
    t0 = time.time()
    mp4, srt, chap, rep = OUT / f"{vid}.mp4", OUT / f"{vid}.srt", OUT / f"{vid}.chapters.txt", OUT / f"{vid}.build.json"
    res = {"id": vid, "qc_version": QC_VERSION, "checked_at": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
    if not mp4.exists():
        return dict(res, status="NOT BUILT", items=[], failed=[], warnings=[])
    before = file_id(mp4)
    R = Report(vid)
    build = None
    try:
        build = json.loads(rep.read_text(encoding="utf-8")); build["_mtime"] = rep.stat().st_mtime
    except Exception:
        pass
    sbp = STORYBOARDS / f"{vid}.json"
    try: sb = json.loads(sbp.read_text(encoding="utf-8"))
    except Exception: sb = None
    notes = []
    if any((CACHE / "build" / d).exists() for d in (vid, f"{vid}.draft")):
        notes.append("a build of this video was running during the check: the files are about to be replaced, check again when it has finished")
    dur = check_file(R, ff, fp, mp4, build, deep)
    if dur is not None:
        silences = check_audio(R, ff, mp4, dur, sb, build)
        try:
            check_narration(R, sb, build, dur, silences)
            check_spoken_log(R, vid, sb, build)
        except Exception as e:      # a storyboard this tool does not understand must not hide the other results
            R.add("C1", "narration checks", False, detail=f"could not be run: {type(e).__name__}: {e}")
        check_picture(R, ff, mp4, dur, deep)
    check_subtitles(R, srt, dur, sb, build)
    chapters_text = check_chapters(R, chap, dur, build)
    check_metadata(R, vid, chapters_text)
    check_thumbnail(R, vid)
    check_build(R, vid, mp4, build, rep, sb)
    if not mp4.exists() or file_id(mp4) != before:
        R.add("I7", "the MP4 stayed the same during the check", False, detail="the file was replaced while it was being checked (a build finished): check again")
    order = lambda it: (it["id"][0], int(it["id"][1:]))
    items = sorted(R.items, key=order)
    h = hashlib.sha256()
    with open(mp4, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""): h.update(block)
    res.update({"status": "FAIL" if any(i["result"] == "FAIL" for i in items) else "PASS", "file": dict(before, name=mp4.name, sha256=h.hexdigest()),
                "seconds": dur and round(dur, 3), "picture_pass": "every frame" if deep else "key frames", "notes": notes,
                "failed": [i["id"] for i in items if i["result"] == "FAIL"], "warnings": [i["id"] for i in items if i["result"] == "WARN"],
                "not_checked": [i["id"] for i in items if i["result"] == "N/A"], "silences": getattr(R, "_silences_found", None),
                "items": items, "checked_in_seconds": round(time.time() - t0, 1)})
    return res


# ---- the summary -------------------------------------------------------------------------------------------------------
def short(it):
    """One item in a table cell: number, name, the measured value in brief, the first entries of its list."""
    s = f"**{it['id']}** {it['name']}"
    m = it.get("measured")
    if isinstance(m, dict):
        m = ", ".join(f"{k.replace('_', ' ')} {v}" for k, v in m.items() if not (v is None or v is False or v == "" or v == [] or (isinstance(v, int) and v == 0)))
    if m not in (None, ""): s += f" ({m})"
    if it.get("detail"): s += f": {it['detail']}"
    shown = MAX_LISTED if it["result"] == "FAIL" else 2
    for x in (it.get("list") or [])[:shown]: s += f"<br>- {x}"
    more = len(it.get("list") or []) - shown
    if more > 0: s += f"<br>- ... and {more} more (see the .qc.json)"
    return s.replace("|", "\\|").replace("\n", " ")


def write_summary():
    """One table over all videos of the course, from the reports on disk."""
    rows, count = [], {"PASS": 0, "FAIL": 0, "not built": 0, "not checked": 0, "stale": 0}
    for vid in all_script_ids():
        mp4, q = OUT / f"{vid}.mp4", QC_DIR / f"{vid}.qc.json"
        if not mp4.exists():
            count["not built"] += 1; rows.append((vid, "not built", "", "")); continue
        try: r = json.loads(q.read_text(encoding="utf-8"))
        except Exception: r = None
        if not r or r.get("status") not in ("PASS", "FAIL"):
            count["not checked"] += 1; rows.append((vid, "not checked", "", "")); continue
        by = {i["id"]: i for i in r["items"]}
        stale = file_id(mp4) != {k: r["file"][k] for k in ("bytes", "mtime")}
        if stale: count["stale"] += 1
        count[r["status"]] += 1
        warn = [short(by[i]) for i in r["warnings"]] + [f"note: {n}" for n in r.get("notes", [])]
        if stale: warn.insert(0, "note: the MP4 has been replaced since this check (checked " + r["checked_at"] + "): check again")
        rows.append((vid, r["status"] + (" (old file)" if stale else ""), "<br>".join(short(by[i]) for i in r["failed"]), "<br>".join(warn)))
    built = [r for r in rows if r[1] != "not built"]
    lines = ["# Quality control: summary", "",
             f"Written by `tools/video_qc.py` on {datetime.datetime.now().strftime('%Y-%m-%d %H:%M')}. One row per video that has an MP4 in `video/production/out/`; the full measurements are in `video/production/out/qc/VNNN.qc.json`, the items are explained in `video/production/QC_CHECKLIST.md`.",
             "",
             f"Videos in the course: {len(rows)}. Built: {len(built)}. PASS: {count['PASS']}. FAIL: {count['FAIL']}. Built but not checked: {count['not checked']}. Not built: {count['not built']}."
             + (f" Checked before the MP4 was replaced: {count['stale']} (check again)." if count["stale"] else ""),
             "",
             "PASS means: every item this tool can measure passed. It does not mean that a person has watched or listened to the video (checklist items marked \"eyes\" and \"ears\").",
             "", "| Video | Result | Failed items | Warnings |", "|---|---|---|---|"]
    lines += [f"| {v} | {s} | {f} | {w} |" for v, s, f, w in built]
    nb = [r[0] for r in rows if r[1] == "not built"]
    if nb:
        lines += ["", "## Not built", "", f"No MP4 in `video/production/out/` (deleted after upload, or not built yet): {len(nb)} videos.", "", compress_ids(nb)]
    SUMMARY.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return count


def compress_ids(ids):
    """['V002', 'V003', 'V004', 'V009'] -> 'V002 to V004, V009'"""
    out, nums = [], sorted(int(v[1:]) for v in ids)
    k = 0
    while k < len(nums):
        j = k
        while j + 1 < len(nums) and nums[j + 1] == nums[j] + 1: j += 1
        out.append(f"V{nums[k]:03d}" if j == k else f"V{nums[k]:03d} to V{nums[j]:03d}")
        k = j + 1
    return ", ".join(out)


# ---- self-test of the parsers ------------------------------------------------------------------------------------------
def selftest():
    bad = []
    def eq(name, got, want):
        if got != want: bad.append(f"{name}: expected {want!r}, got {got!r}")
    # subtitles
    cues, problems = parse_srt("1\n00:00:01,000 --> 00:00:02,500\nHello\nthere\n\n2\n00:00:02,540 --> 00:01:03,000\nSecond cue\n")
    eq("srt: two cues", [(c["n"], c["start"], c["end"], c["lines"]) for c in cues], [(1, 1.0, 2.5, ["Hello", "there"]), (2, 2.54, 63.0, ["Second cue"])])
    eq("srt: no problems", problems, [])
    cues, problems = parse_srt("1\n00:00:01,000 -> 00:00:02,500\nbroken arrow\n\n3\n01:00:00,000 --> 01:00:01,000\n\n")
    eq("srt: a broken time line is reported, an empty cue is kept", (len(cues), len(problems), cues[0]["lines"], cues[0]["start"]), (1, 2, [], 3600.0))
    eq("srt: CRLF and BOM", len(parse_srt("\ufeff1\r\n00:00:00,000 --> 00:00:01,000\r\nA\r\n\r\n2\r\n00:00:01,000 --> 00:00:02,000\r\nB\r\n")[0]), 2)
    eq("srt: coverage, in order", srt_coverage([{"lines": ["One two", "three."]}, {"lines": ["Four  five."]}],
                                                 [{"type": "narration", "i": 0, "text": "One two three."}, {"type": "hold", "i": 1, "text": ""}, {"type": "narration", "i": 2, "text": "Four five."}]), (100.0, []))
    pct, missing = srt_coverage([{"lines": ["One two three."]}], [{"type": "narration", "i": 0, "text": "One two three."}, {"type": "narration", "i": 1, "text": "Not there."}])
    eq("srt: coverage, a missing beat", (round(pct, 1), missing), (58.3, [1]))
    eq("srt: forbidden text", [n for n, p in SRT_FORBIDDEN if re.search(p, "Run `git log` **now** [PAUSE] and see [rejected]")], ["[PAUSE]", "a direction in capitals in square brackets", "** (bold marker)", "backtick"])
    eq("srt: a glob pattern is not markup", [n for n, p in SRT_FORBIDDEN if re.search(p, "write docs/**. Or **/*.py, or src/**/test")], [])
    eq("srt: a bold marker is", [n for n, p in SRT_FORBIDDEN if re.search(p, "The **index")] + [n for n, p in SRT_FORBIDDEN if re.search(p, "index** is")], ["** (bold marker)"] * 2)
    # chapters
    ch, problems = parse_chapters("0:00 Hook\n0:59 Introduction\n1:02:03 Recap\n")
    eq("chapters: parse", (ch, problems), ([(0, "Hook"), (59, "Introduction"), (3723, "Recap")], []))
    eq("chapters: good list", chapter_problems(ch, 4000.0), {})
    eq("chapters: a line that is not a chapter", len(parse_chapters("Hook 0:00\n")[1]), 1)
    eq("chapters: rules", sorted(chapter_problems([(5, "A"), (12, ""), (11, "C" * 100)], 15.0)), ["ascending", "first", "length", "title"])
    eq("chapters: too few, last too short", sorted(chapter_problems([(0, "A"), (60, "B")], 65.0)), ["count", "length"])
    eq("chapters: last one after the end", sorted(chapter_problems([(0, "A"), (20, "B"), (40, "C")], 40.0)), ["end"])
    # silences
    log = ("[silencedetect @ 0x1] [info] silence_start: -0.002\n[silencedetect @ 0x1] [info] silence_end: 4.5 | silence_duration: 4.5\n"
           "[silencedetect @ 0x1] [info] silence_start: 30\n[silencedetect @ 0x1] [info] silence_end: 39.5 | silence_duration: 9.5\n[x] [info] silence_start: 58.2\n")
    sil = parse_silences(log)
    eq("silences: parse, an open one at the end", sil, [(0.0, 4.5), (30.0, 39.5), (58.2, None)])
    beats = [{"i": 0, "type": "hold", "why": "title", "section": "TITLE"}, {"i": 1, "type": "hold", "why": "section", "section": "HOOK"}, {"i": 2, "type": "narration"},
             {"i": 3, "type": "hold", "why": "pause", "section": "HOOK"}, {"i": 4, "type": "narration"}]
    quiet = expected_quiet(beats, [1.0, 3.0, 4.5, 31.0, 33.0], 60.0, 1.0)
    eq("silences: what the storyboard expects", [(a, b) for a, b, _ in quiet], [(0.0, 1.0), (1.0, 3.0), (3.0, 4.5), (31.0, 33.0)])
    found = explain_silences(sil, quiet, 60.0, margin=0.75, shortest=1.0)
    eq("silences: mapping", [(x["start"], x["seconds"], x["unexplained"]) for x in found], [(0.0, 4.5, 0.0), (30.0, 9.5, 6.0), (58.2, 1.8, 1.8)])
    eq("silences: the pause hold is named", found[1]["why"], ["hold of beat 3: pause in HOOK"])
    eq("overlap of joined spans", overlap(0.0, 10.0, [(1.0, 3.0), (2.0, 4.0), (8.0, 20.0)]), 5.0)
    # metadata, images, ids
    meta = parse_metadata("## Part 0\n\n### V001\n\nTitle:\n\n```text\nA title\n```\n\nDescription:\n\n```text\nTwo lines\nof text.\n```\n\nThumbnail: x\n\n### V002\n\nTitle:\n\n```text\nB\n```\n")
    eq("metadata", meta, {"V001": {"title": "A title", "description": "Two lines\nof text."}, "V002": {"title": "B", "description": None}})
    eq("compress ids", compress_ids(["V002", "V003", "V004", "V009"]), "V002 to V004, V009")
    eq("frame detail: flat frame", frame_detail(bytes([40]) * (FRAME_W * FRAME_H))[0], 0.0)
    eq("frame detail: stripes", round(frame_detail((bytes([0]) * 4 + bytes([200]) * 4) * (FRAME_W * FRAME_H // 8))[0], 1), 24.7)
    eq("error lines", error_lines("[info] fine\n[h264 @ 0x1] [error] bad NAL\n"), ["[h264 @ 0x1] [error] bad NAL"])
    bad += narration_selftest()
    tgt = loudness_target()
    if "fallback" in tgt[2]: bad.append("the loudness target could not be read from loudnorm() in tools/video_build.py")
    print("\n".join("FAIL  " + x for x in bad) if bad else f"qc self-test: subtitles, chapters, silences, metadata, frame measures and the pace of voice clips (C1, C2): all correct (loudness target read from the builder: {tgt[0]:g} LUFS, {tgt[1]:g} dBTP)")
    return 1 if bad else 0


def narration_selftest():
    """C1 and C2 on a made-up video whose one beat is a clip in a stand-in voice cache: a clip cut short fails both, even with
    its .ok mark (V071 beat 39: 22 words in 3.94 s, marked verified); a whole clip passes both; a clip just outside the bounds
    whose mark says "three identical takes" is a warning in both.  Nothing real is read or written."""
    import tempfile
    bad = []
    said = "Here are the candidates on the first-parent line again. HEAD now points at commit 0 7 4 d, and at no branch."
    sb = {"slides": [], "beats": [{"i": 0, "type": "narration", "slide": 1, "section": "DEMO", "text": said}]}
    real = vb.tts_path
    with tempfile.TemporaryDirectory() as d:
        vb.tts_path = lambda spoken, voice, rate: pathlib.Path(d) / f"{sha1(f'{voice}|{rate}|{spoken}')}.wav"
        try:
            for seconds, want in ((7.30, ("PASS", "PASS")), (3.94, ("FAIL", "FAIL"))):
                p = vb.tts_path(said, "Tara", 165)
                n = int(seconds * vb.SR) - 480 - 2400
                vb.write_wav(p, vb.silence(0.2) + __import__("array").array("h", [5000 if (k // 50) % 2 else -5000 for k in range(n)]) + vb.silence(0.2))
                p.with_suffix(".ok").write_text(f"{seconds:.3f}\n")
                beat = len(vb.trim_voice(vb.read_wav(p))) / vb.SR + vb.DRAFT_GAP
                build = {"beat_starts": [vb.LEAD], "seconds": vb.LEAD + beat, "audio": {"mode": "draft", "voice": "Tara", "rate": 165}, "_mtime": time.time() + 60}
                R = Report("V000")
                check_narration(R, sb, build, vb.LEAD + beat, None)
                got = tuple(next(i["result"] for i in R.items if i["id"] == x) for x in ("C1", "C2"))
                if got != want: bad.append(f"C1 and C2 for a clip of {seconds} s: {got}, expected {want}")
            # the same short clip, but the beat in the video is as long as a whole one: C1 passes, C2 still fails on the clip itself
            build["seconds"] = vb.LEAD + 7.30 + vb.DRAFT_GAP
            R = Report("V000")
            check_narration(R, sb, build, build["seconds"], None)
            c2 = next(i for i in R.items if i["id"] == "C2")
            if c2["result"] != "FAIL" or not c2.get("measured", {}).get("outside_the_pace_bounds"): bad.append(f"C2 accepted a marked clip outside the pace bounds: {c2}")
            # a short beat (under PACE_MIN_WORDS words) by its own bounds: a marked clip that was cut short fails both (0.93 s, 34 letters/s:
            # the old bounds passed it), a whole one passes, one just outside with the three-takes mark is a warning
            six = "The two library commits have diverged."
            sb6 = {"slides": [], "beats": [{"i": 0, "type": "narration", "slide": 1, "section": "DEMO", "text": six}]}
            for seconds, mark, want in ((0.93, "0.972", ("FAIL", "FAIL")), (0.93, f"0.972 {vb.MARK_THREE}", ("FAIL", "FAIL")), (1.90, f"1.942 {vb.MARK_TWO}", ("PASS", "PASS")), (1.90, "1.942", ("PASS", "PASS")),
                                        (1.60, f"1.642 {vb.MARK_THREE} (fast: 3.75 words/s, 20.0 letters/s)", ("WARN", "WARN")), (1.60, "1.642", ("FAIL", "FAIL")), (6.50, "6.542", ("FAIL", "FAIL"))):
                p = vb.tts_path(six, "Tara", 165)
                n = int(seconds * vb.SR) - 480 - 2400
                vb.write_wav(p, vb.silence(0.2) + __import__("array").array("h", [5000 if (k // 50) % 2 else -5000 for k in range(n)]) + vb.silence(0.2))
                p.with_suffix(".ok").write_text(mark + "\n")
                beat = len(vb.trim_voice(vb.read_wav(p))) / vb.SR + vb.DRAFT_GAP
                build = {"beat_starts": [vb.LEAD], "seconds": vb.LEAD + beat, "audio": {"mode": "draft", "voice": "Tara", "rate": 165}, "_mtime": time.time() + 60}
                R = Report("V000")
                check_narration(R, sb6, build, vb.LEAD + beat, None)
                got = tuple(next(i["result"] for i in R.items if i["id"] == x) for x in ("C1", "C2"))
                if got != want: bad.append(f"C1 and C2 for a short clip of {seconds} s, marked {mark!r}: {got}, expected {want}")
            # the three-identical-takes rule: a clip outside the bounds whose mark says so is a warning in C1 and C2, with its pace;
            # with a plain mark, or outside the wide bounds, or loud, it fails as before (V037: 9 words in 1.94 s, every time)
            nine = "None of the three needs a bug in Git."
            sb9 = {"slides": [], "beats": [{"i": 0, "type": "narration", "slide": 1, "section": "HOOK", "text": nine}]}
            for seconds, level, mark, want in ((1.94, 5000, f"1.982 {vb.MARK_THREE} (fast: 4.63 words/s, 14.4 letters/s)", ("WARN", "WARN")), (1.94, 5000, "1.982", ("FAIL", "FAIL")),
                                               (1.94, 5000, f"1.982 {vb.MARK_TWO} (4.63 words/s, 14.4 letters/s)", ("FAIL", "FAIL")),
                                               (1.60, 5000, f"1.642 {vb.MARK_THREE}", ("FAIL", "FAIL")), (1.94, 22000, f"1.982 {vb.MARK_THREE}", ("FAIL", "FAIL")),
                                               (2.50, 5000, f"2.542 {vb.MARK_TWO} (3.60 words/s, 11.2 letters/s)", ("PASS", "PASS"))):
                p = vb.tts_path(nine, "Tara", 165)
                n = int(seconds * vb.SR) - 480 - 2400
                vb.write_wav(p, vb.silence(0.2) + __import__("array").array("h", [level if (k // 50) % 2 else -level for k in range(n)]) + vb.silence(0.2))
                p.with_suffix(".ok").write_text(mark + "\n")
                beat = len(vb.trim_voice(vb.read_wav(p))) / vb.SR + vb.DRAFT_GAP
                build = {"beat_starts": [vb.LEAD], "seconds": vb.LEAD + beat, "audio": {"mode": "draft", "voice": "Tara", "rate": 165}, "_mtime": time.time() + 60}
                R = Report("V000")
                check_narration(R, sb9, build, vb.LEAD + beat, None)
                c1, c2 = (next(i for i in R.items if i["id"] == x) for x in ("C1", "C2"))
                if (c1["result"], c2["result"]) != want: bad.append(f"C1 and C2 for a clip of {seconds} s, level {level}, marked {mark!r}: {(c1['result'], c2['result'])}, expected {want}")
                elif want == ("WARN", "WARN") and not all("words/s" in " ".join(c.get("list", [])) and "listen" in " ".join(c.get("list", [])) for c in (c1, c2)):
                    bad.append(f"C1 and C2 do not list the beat accepted by three identical takes with its pace: {c1.get('list')} {c2.get('list')}")
        finally:
            vb.tts_path = real
    return bad


def main():
    argv = sys.argv[1:]
    if "--selftest" in argv:
        return selftest()
    deep = "--deep" in argv
    args = [a for a in argv if not a.startswith("--")]
    if "--summary" in argv:
        print(f"summary: {write_summary()}  -> {rel(SUMMARY)}"); return 0
    if not args:
        print(__doc__); return 2
    ff, fp = vb.need_ffmpeg()
    QC_DIR.mkdir(parents=True, exist_ok=True)
    failed = checked = 0
    for vid in expand_ids(args):
        r = qc_one(vid, ff, fp, deep)
        if r["status"] == "NOT BUILT":
            print(f"{vid}: not built", flush=True); continue
        tmp = QC_DIR / f"{vid}.qc.json.part"
        tmp.write_text(json.dumps(r, indent=1, ensure_ascii=False), encoding="utf-8")
        os.replace(tmp, QC_DIR / f"{vid}.qc.json")
        checked += 1
        failed += r["status"] == "FAIL"
        print(f"{vid}: {r['status']}" + (f"  failed: {' '.join(r['failed'])}" if r["failed"] else "") + (f"  warnings: {' '.join(r['warnings'])}" if r["warnings"] else "")
              + (f"  not checked: {' '.join(r['not_checked'])}" if r["not_checked"] else "") + f"  ({r['checked_in_seconds']:.0f} s)", flush=True)
    count = write_summary()
    print(f"qc: {checked} checked, {failed} failed  -> {rel(SUMMARY)}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
