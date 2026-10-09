#!/usr/bin/env python3
"""Upload and schedule the 201 course videos on YouTube. Standard library only.

Commands (run them in this order; every command accepts --dry-run):

    plan --start "YYYY-MM-DD HH:MM"   build video/youtube/plan.json and PLAN.md
    check                             offline preflight of all 201 videos
    auth                              one-time Google sign-in (OAuth loopback flow)
    whoami [--confirm]                show, then confirm, the channel of the token
    upload --only V001 | --next N | --all
    verify                            compare YouTube with the plan
    retime                            apply changed publish times to uploaded videos
    status | report                   write REPORT.md and report.csv
    --selftest                        offline tests, including a fake API server

Safety rules built into the tool:
  * every video is inserted as private with a publish time in the future;
  * a video that has a YouTube ID in state.json is never inserted again;
  * there is no delete command and no call to any delete method;
  * secrets (OAuth client file, tokens, upload session addresses) live in
    ~/.config/git-mastery-youtube/, outside the repository, with mode 600;
  * tokens are never printed; no password is read, stored or asked for.

The documented limits and quota costs below were read from the official
documentation on 2026-10-10. Sources are listed in video/youtube/README.md.
"""
from __future__ import annotations

import argparse
import base64
import concurrent.futures
import contextlib
import csv
import datetime as dt
import hashlib
import http.client
import http.server
import io
import json
import math
import os
import random
import re
import secrets
import shutil
import struct
import sys
import tempfile
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import webbrowser

try:
    from zoneinfo import ZoneInfo
except Exception:  # pragma: no cover
    ZoneInfo = None

# --------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------

TOTAL_VIDEOS = 201
REPO_SLUG = "harshaksh-singh/git-github-mastery"
REPO_URL = "https://github.com/" + REPO_SLUG
RELEASE_BATCHES = [  # (tag, first, last)
    ("videos-batch-01", 1, 33), ("videos-batch-02", 34, 66),
    ("videos-batch-03", 67, 99), ("videos-batch-04", 100, 133),
    ("videos-batch-05", 134, 166), ("videos-batch-06", 167, 201),
]
OWNER_TZ = "Asia/Kolkata"
QUOTA_TZ = "America/Los_Angeles"  # "Daily quotas reset at midnight Pacific Time (PT)."

API_BASE = "https://www.googleapis.com"
AUTH_URI = "https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_URI = "https://oauth2.googleapis.com/token"
# youtube.upload: videos.insert, thumbnails.set.
# youtube.force-ssl: captions.insert (only this scope or youtubepartner),
# playlists, playlistItems, videos.list/update, channels.list.
SCOPES = [
    "https://www.googleapis.com/auth/youtube.upload",
    "https://www.googleapis.com/auth/youtube.force-ssl",
]

# Documented limits (see README.md, section "What the documentation says").
MAX_TITLE_CHARS = 100          # videos resource, snippet.title
MAX_DESCRIPTION_BYTES = 5000   # videos resource, snippet.description (bytes)
MAX_TAGS_CHARS = 500           # videos resource, snippet.tags[]
FORBIDDEN_CHARS = "<>"         # not allowed in title and description
MAX_THUMBNAIL_BYTES = 50 * 1024 * 1024   # thumbnails.set: "Maximum file size: 50MB"
WARN_THUMBNAIL_BYTES = 2 * 1024 * 1024   # Help Center: 2 MB on mobile
MIN_THUMBNAIL_WIDTH = 640                # Help Center: minimum width 640 pixels
MAX_CAPTION_BYTES = 100 * 1024 * 1024    # captions.insert: "Maximum file size: 100MB"
MAX_VIDEO_BYTES = 256 * 1024 ** 3        # videos.insert: "Maximum file size: 256GB"
MIN_CHAPTERS = 3
MIN_CHAPTER_SECONDS = 10
MAX_PLAYLIST_TITLE_CHARS = 150  # not confirmed in the reference; conservative

# Quota costs per call (determine_quota_cost page). videos.insert is charged
# to its own bucket ("100 quota per day. Each call costs 1 quota.").
QUOTA_COST = {
    "channels.list": 1, "videos.list": 1, "playlists.list": 1,
    "playlistItems.list": 1, "videoCategories.list": 1,
    "playlists.insert": 50, "playlistItems.insert": 50,
    "thumbnails.set": 50, "captions.insert": 400, "captions.list": 50,
    "videos.update": 50,
}
UPLOAD_BUCKET_CALLS = {"videos.insert"}
DEFAULT_DAILY_UNITS = 10000
DEFAULT_DAILY_UPLOADS = 100
DEFAULT_RESERVE_UNITS = 100

DEFAULT_CONFIG = {
    "repo_url": REPO_URL,
    "link_line": "Course book, labs and exercises: " + REPO_URL,
    "category_id": "27",            # Education; whoami prints the name to confirm
    "region_code": "IN",
    "language": "en",
    "audio_language": "en",
    "caption_language": "en",
    "caption_name": "",
    "made_for_kids": False,
    "contains_synthetic_media": None,   # None = do not send the field
    "notify_subscribers": True,          # the API default
    "license": "youtube",
    "embeddable": True,
    "public_stats_viewable": True,
    "playlist_privacy": "public",
    "course_playlist_title": "Git & GitHub Mastery: the complete course",
    "part_playlist_title": "Git & GitHub Mastery, Part {num}: {name}",
    "playlist_description": "Git and GitHub Deep Mastery, a 201-video course. "
                            "Book, labs and exercises: " + REPO_URL,
    "base_tags": ["git", "github", "git tutorial", "github tutorial",
                  "version control", "git course", "software engineering"],
    "part_tags": {
        "0": ["git for beginners", "learn git"],
        "1": ["git basics", "git fundamentals"],
        "2": ["git merge", "git rebase", "git branching"],
        "3": ["git recovery", "git reflog", "git bisect"],
        "4": ["git internals", "git objects"],
        "5": ["github pull requests", "github collaboration"],
        "6": ["github actions", "ci cd"],
        "7": ["git security", "supply chain security"],
        "8": ["git workflow", "engineering practice"],
        "9": ["incident response", "production debugging"],
        "10": ["senior engineer interview", "git interview questions"],
        "11": ["advanced git", "git at scale"],
    },
    "video_tags": {},               # {"V001": ["extra tag"]}
}

STEP_NAMES = ["insert", "thumbnail", "captions", "playlists", "verify"]


class Fatal(Exception):
    """An error the owner must act on. Printed without a traceback."""


class StopRun(Exception):
    """Stop the run cleanly (quota or daily limit). Not a failure."""


class HttpError(Exception):
    def __init__(self, status, reason, message, body=b""):
        super().__init__(f"HTTP {status} {reason}: {message}")
        self.status, self.reason, self.message, self.body = status, reason, message, body


class SessionExpired(Exception):
    pass


# --------------------------------------------------------------------------
# Paths
# --------------------------------------------------------------------------

class Paths:
    def __init__(self, root=None, config_dir=None, cache_dir=None):
        self.root = os.path.abspath(root or os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
        v = os.path.join(self.root, "video")
        self.metadata = os.path.join(v, "youtube-metadata.md")
        self.thumb_data = os.path.join(v, "thumbnails", "thumbnail-data.json")
        self.curriculum = os.path.join(v, "video-curriculum.md")
        self.thumbs = os.path.join(v, "thumbnails")
        self.out = os.path.join(v, "production", "out")
        self.qc = os.path.join(self.out, "QC-FINAL.md")
        self.qc_dir = os.path.join(self.out, "qc")
        self.yt = os.path.join(v, "youtube")
        self.plan = os.path.join(self.yt, "plan.json")
        self.plan_md = os.path.join(self.yt, "PLAN.md")
        self.state = os.path.join(self.yt, "state.json")
        self.report_md = os.path.join(self.yt, "REPORT.md")
        self.report_csv = os.path.join(self.yt, "report.csv")
        self.verify_md = os.path.join(self.yt, "VERIFY.md")
        self.config = os.path.join(self.yt, "config.json")
        self.lock = os.path.join(self.yt, ".lock")
        self.config_dir = config_dir or os.path.expanduser("~/.config/git-mastery-youtube")
        self.client_secret = os.path.join(self.config_dir, "client_secret.json")
        self.token = os.path.join(self.config_dir, "token.json")
        self.sessions = os.path.join(self.config_dir, "sessions.json")
        self.cache_dir = cache_dir or os.path.expanduser("~/Library/Caches/git-mastery-youtube")

    def rel(self, p):
        return os.path.relpath(p, self.root)


def vid_name(n):
    return f"V{n:03d}"


def vid_num(v):
    return int(v[1:])


def release_tag(n):
    for tag, a, b in RELEASE_BATCHES:
        if a <= n <= b:
            return tag
    raise ValueError(n)


def asset_url(vid, ext="mp4"):
    return f"{REPO_URL}/releases/download/{release_tag(vid_num(vid))}/{vid}.{ext}"


# --------------------------------------------------------------------------
# Small helpers
# --------------------------------------------------------------------------

def tz(name):
    if ZoneInfo is not None:
        try:
            return ZoneInfo(name)
        except Exception:
            pass
    if name == OWNER_TZ:  # India has one fixed offset and no daylight saving time
        return dt.timezone(dt.timedelta(hours=5, minutes=30), "IST")
    raise Fatal(f"time zone data for {name} is not available on this machine")


def now_utc():
    return dt.datetime.now(dt.timezone.utc)


def rfc3339(t, zone=None):
    """RFC 3339 text with seconds. zone=None gives UTC with a trailing Z."""
    if zone is None:
        return t.astimezone(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    s = t.astimezone(zone).strftime("%Y-%m-%dT%H:%M:%S%z")
    return s[:-2] + ":" + s[-2:]


def parse_rfc3339(s):
    s = s.strip()
    if s.endswith(("Z", "z")):
        s = s[:-1] + "+00:00"
    s = re.sub(r"\.(\d+)", lambda m: "." + (m.group(1) + "000000")[:6], s)
    return dt.datetime.fromisoformat(s)


def parse_local_start(text, zone):
    try:
        t = dt.datetime.strptime(text.strip(), "%Y-%m-%d %H:%M")
    except ValueError:
        raise Fatal(f'--start must look like "2026-10-20 09:00" (got {text!r})')
    return t.replace(tzinfo=zone)


def slot_time(start, gap_hours, index):
    """Slot `index` (0-based). Arithmetic is done in UTC, so it is exact
    across midnight, month ends and any daylight-saving change."""
    return (start.astimezone(dt.timezone.utc)
            + dt.timedelta(seconds=round(gap_hours * 3600)) * index)


def fmt_local(t, zone):
    return t.astimezone(zone).strftime("%Y-%m-%d %H:%M")


def atomic_write(path, text, mode=None):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = f"{path}.tmp{os.getpid()}"
    flags = os.O_WRONLY | os.O_CREAT | os.O_TRUNC
    fd = os.open(tmp, flags, mode if mode is not None else 0o644)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(text)
            f.flush()
            os.fsync(f.fileno())
        if mode is not None:
            os.chmod(tmp, mode)
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)


def write_json(path, obj, mode=None):
    atomic_write(path, json.dumps(obj, indent=1, ensure_ascii=False) + "\n", mode)


def read_json(path, default=None):
    if not os.path.exists(path):
        return default
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def parse_clock(text):
    """'18:49' or '1:02:03' -> seconds."""
    parts = [int(x) for x in text.strip().split(":")]
    if not 2 <= len(parts) <= 3 or any(p < 0 for p in parts) or any(p > 59 for p in parts[1:]):
        raise ValueError(text)
    s = 0
    for p in parts:
        s = s * 60 + p
    return s


def parse_iso_duration(text):
    m = re.fullmatch(r"P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?", text or "")
    if not m:
        return None
    d, h, mi, s = (int(x or 0) for x in m.groups())
    return d * 86400 + h * 3600 + mi * 60 + s


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


# --------------------------------------------------------------------------
# Reading the course files
# --------------------------------------------------------------------------

def parse_metadata(text):
    """video/youtube-metadata.md -> {vid: {title, description, thumbnail}}."""
    out, order = {}, []
    sections = re.split(r"(?m)^### (V\d{3})\s*$", text)
    for i in range(1, len(sections), 2):
        vid, body = sections[i], sections[i + 1]
        entry = {}
        for key in ("Title", "Description"):
            m = re.search(rf"(?ms)^{key}:\s*\n+```text\n(.*?)\n```", body)
            if m:
                entry[key.lower()] = m.group(1)
        m = re.search(r"(?m)^Thumbnail: \[`([^`]+)`\]", body)
        if m:
            entry["thumbnail"] = m.group(1)
        if vid in out:
            raise Fatal(f"{vid} appears twice in youtube-metadata.md")
        out[vid] = entry
        order.append(vid)
    return out, order


def parse_curriculum(text):
    """video-curriculum.md -> (parts {num: {name, first, last}}, video_part {vid: num})."""
    parts, video_part = {}, {}
    for m in re.finditer(r"(?m)^\| (\d+): ([^|]+?) \| [^|]*\| V(\d{3}) to V(\d{3}) \| (\d+) \|", text):
        num = int(m.group(1))
        parts[num] = {"name": m.group(2).strip(), "first": int(m.group(3)),
                      "last": int(m.group(4)), "count": int(m.group(5))}
    for m in re.finditer(r"(?m)^\| (V\d{3}) \| (.+?) \| (\d+) \| ", text):
        video_part[m.group(1)] = int(m.group(3))
    return parts, video_part


def parse_qc(text):
    """QC-FINAL.md -> {vid: {status, seconds, checked}}."""
    out = {}
    for m in re.finditer(r"(?m)^\| (V\d{3}) \| (\w+) \| ([^|]*) \| ([\d:]+) \|", text):
        out[m.group(1)] = {"status": m.group(2), "checked": m.group(3).strip(),
                           "seconds": parse_clock(m.group(4))}
    return out


def parse_chapters(text):
    """'0:00 Hook' lines -> [(seconds, stamp, title)]; raises ValueError on a bad line."""
    out = []
    for n, line in enumerate(text.splitlines(), 1):
        if not line.strip():
            continue
        m = re.fullmatch(r"((?:\d{1,2}:)?\d{1,2}:\d{2})\s+(\S.*)", line.strip())
        if not m:
            raise ValueError(f"line {n} is not 'M:SS Title': {line!r}")
        out.append((parse_clock(m.group(1)), m.group(1), m.group(2).strip()))
    return out


def validate_chapters(chapters, duration_seconds=None):
    """Rules from the Help Center: first at 0:00, at least three, ascending,
    each at least 10 seconds long."""
    errs = []
    if len(chapters) < MIN_CHAPTERS:
        errs.append(f"chapters: {len(chapters)} listed, at least {MIN_CHAPTERS} required")
    if chapters and chapters[0][0] != 0:
        errs.append(f"chapters: the first one starts at {chapters[0][1]}, it must start at 0:00")
    for i, (sec, stamp, title) in enumerate(chapters):
        nxt = chapters[i + 1][0] if i + 1 < len(chapters) else duration_seconds
        if i + 1 < len(chapters) and nxt <= sec:
            errs.append(f"chapters: {chapters[i + 1][1]} is not after {stamp}")
        elif nxt is not None and nxt - sec < MIN_CHAPTER_SECONDS:
            errs.append(f"chapters: '{title}' at {stamp} lasts {nxt - sec} s, "
                        f"the minimum is {MIN_CHAPTER_SECONDS} s")
        if any(c in title for c in FORBIDDEN_CHARS):
            errs.append(f"chapters: title {title!r} contains < or >")
    return errs


def parse_srt(text):
    """Returns (cues, errors). A cue is (start_ms, end_ms, text)."""
    cues, errs = [], []
    blocks = re.split(r"\n\s*\n", text.replace("\r\n", "\n").strip("﻿\n "))
    ts = r"(\d{2}):(\d{2}):(\d{2}),(\d{3})"
    last_start = -1
    for i, block in enumerate(blocks, 1):
        lines = block.split("\n")
        if len(lines) < 3:
            errs.append(f"cue {i}: fewer than three lines")
            continue
        if not lines[0].strip().isdigit():
            errs.append(f"cue {i}: no cue number")
        m = re.fullmatch(rf"{ts} --> {ts}", lines[1].strip())
        if not m:
            errs.append(f"cue {i}: bad time line {lines[1]!r}")
            continue
        g = [int(x) for x in m.groups()]
        a = ((g[0] * 60 + g[1]) * 60 + g[2]) * 1000 + g[3]
        b = ((g[4] * 60 + g[5]) * 60 + g[6]) * 1000 + g[7]
        if b <= a:
            errs.append(f"cue {i}: ends before it starts")
        if a < last_start:
            errs.append(f"cue {i}: starts before the previous cue")
        last_start = a
        body = "\n".join(lines[2:]).strip()
        if not body:
            errs.append(f"cue {i}: empty text")
        cues.append((a, b, body))
    if not cues:
        errs.append("no cues")
    return cues, errs


def png_size(path):
    with open(path, "rb") as f:
        head = f.read(24)
    if len(head) < 24 or head[:8] != b"\x89PNG\r\n\x1a\n" or head[12:16] != b"IHDR":
        return None
    return struct.unpack(">II", head[16:24])


def load_config(paths):
    cfg = json.loads(json.dumps(DEFAULT_CONFIG))
    user = read_json(paths.config)
    if user:
        unknown = sorted(set(user) - set(cfg))
        if unknown:
            raise Fatal(f"{paths.rel(paths.config)}: unknown keys {unknown}")
        cfg.update(user)
    return cfg


# --------------------------------------------------------------------------
# Validation and plan building
# --------------------------------------------------------------------------

def tags_length(tags):
    """Length as the API counts it: commas between tags count, and a tag with
    a space counts two more characters for the quotation marks."""
    return sum(len(t) + (2 if " " in t else 0) for t in tags) + max(0, len(tags) - 1)


def validate_title(title):
    errs = []
    if not title or not title.strip():
        errs.append("title: empty")
    if len(title) > MAX_TITLE_CHARS:
        errs.append(f"title: {len(title)} characters, the limit is {MAX_TITLE_CHARS}")
    bad = sorted({c for c in title if c in FORBIDDEN_CHARS})
    if bad:
        errs.append(f"title: contains {' '.join(bad)}, which YouTube rejects")
    if title != title.strip() or "\n" in title:
        errs.append("title: leading/trailing space or a line break")
    return errs


def validate_description(desc):
    errs = []
    size = len(desc.encode("utf-8"))
    if size > MAX_DESCRIPTION_BYTES:
        errs.append(f"description: {size} bytes, the limit is {MAX_DESCRIPTION_BYTES}")
    bad = sorted({c for c in desc if c in FORBIDDEN_CHARS})
    if bad:
        errs.append(f"description: contains {' '.join(bad)}, which YouTube rejects")
    return errs


def validate_tags(tags):
    errs = []
    n = tags_length(tags)
    if n > MAX_TAGS_CHARS:
        errs.append(f"tags: {n} characters as YouTube counts them, the limit is {MAX_TAGS_CHARS}")
    for t in tags:
        if not t.strip() or t != t.strip():
            errs.append(f"tags: empty tag or stray space in {t!r}")
        if any(c in t for c in '<>,"'):
            errs.append(f"tags: {t!r} contains one of < > , \"")
    lowered = [t.lower() for t in tags]
    dup = sorted({t for t in lowered if lowered.count(t) > 1})
    if dup:
        errs.append(f"tags: repeated {dup}")
    return errs


def command_tag(command):
    """'git cat-file -p' -> 'git cat-file'; anything else -> None."""
    words = (command or "").split()
    if len(words) >= 2 and words[0] in ("git", "gh") and re.fullmatch(r"[a-z][a-z-]*", words[1]):
        return f"{words[0]} {words[1]}"
    return None


def build_tags(cfg, vid, part, command):
    tags = list(cfg["base_tags"]) + list(cfg["part_tags"].get(str(part), []))
    ct = command_tag(command)
    if ct:
        tags.append(ct)
    tags += cfg["video_tags"].get(vid, [])
    seen, out = set(), []
    for t in tags:  # drop exact repeats, keep order
        if t.lower() not in seen:
            seen.add(t.lower())
            out.append(t)
    return out


def assemble_description(description, chapters, link_line):
    lines = [description.strip(), ""]
    lines += [f"{stamp} {title}" for _, stamp, title in chapters]
    lines += ["", link_line]
    return "\n".join(lines)


def playlist_defs(cfg, parts):
    defs = [{"key": "course", "title": cfg["course_playlist_title"],
             "description": cfg["playlist_description"]}]
    for num in sorted(parts):
        defs.append({"key": f"part-{num:02d}",
                     "title": cfg["part_playlist_title"].format(num=num, name=parts[num]["name"]),
                     "description": f"Part {num} of 12: {parts[num]['name']} "
                                    f"(videos {parts[num]['first']} to {parts[num]['last']}). "
                                    + cfg["playlist_description"]})
    return defs


def load_sources(paths):
    """Everything `plan` and `check` need, with problems collected, not raised."""
    problems = []

    def read(p):
        try:
            with open(p, encoding="utf-8") as f:
                return f.read()
        except OSError as e:
            problems.append(f"cannot read {paths.rel(p)}: {e.strerror}")
            return ""

    meta, order = parse_metadata(read(paths.metadata))
    parts, video_part = parse_curriculum(read(paths.curriculum))
    qc = parse_qc(read(paths.qc))
    tdata = {}
    try:
        tdata = {x["id"]: x for x in read_json(paths.thumb_data, [])}
    except (ValueError, KeyError) as e:
        problems.append(f"thumbnail-data.json: {e}")
    return {"meta": meta, "order": order, "parts": parts, "video_part": video_part,
            "qc": qc, "tdata": tdata, "problems": problems}


def build_item(paths, cfg, src, vid, publish_utc, zone):
    """One plan entry plus its list of violations."""
    errs = []
    n = vid_num(vid)
    m = src["meta"].get(vid, {})
    title = m.get("title", "")
    desc = m.get("description", "")
    if "title" not in m:
        errs.append("metadata: no title in youtube-metadata.md")
    if "description" not in m:
        errs.append("metadata: no description in youtube-metadata.md")
    part = src["video_part"].get(vid)
    if part is None or part not in src["parts"]:
        errs.append("curriculum: the video is not in the master table")
        part_name = ""
    else:
        p = src["parts"][part]
        part_name = p["name"]
        if not p["first"] <= n <= p["last"]:
            errs.append(f"curriculum: master table says part {part}, "
                        f"but that part covers V{p['first']:03d} to V{p['last']:03d}")
    td = src["tdata"].get(vid, {})
    if td and td.get("part") != part:
        errs.append(f"thumbnail-data.json says part {td.get('part')}, the curriculum says {part}")
    qc = src["qc"].get(vid)
    duration = qc["seconds"] if qc else None
    size = sha = None
    qcj = read_json(os.path.join(paths.qc_dir, f"{vid}.qc.json"))
    if qcj:
        size = qcj.get("file", {}).get("bytes")
        sha = qcj.get("file", {}).get("sha256")
        if qcj.get("seconds"):
            duration_exact = float(qcj["seconds"])
        else:
            duration_exact = None
    else:
        duration_exact = None
    chapters = []
    cpath = os.path.join(paths.out, f"{vid}.chapters.txt")
    try:
        with open(cpath, encoding="utf-8") as f:
            chapters = parse_chapters(f.read())
        errs += validate_chapters(chapters, duration)
    except OSError:
        errs.append(f"chapters: {paths.rel(cpath)} is missing")
    except ValueError as e:
        errs.append(f"chapters: {e}")
    full_desc = assemble_description(desc, chapters, cfg["link_line"])
    tags = build_tags(cfg, vid, part, td.get("command", ""))
    errs += validate_title(title) + validate_description(full_desc) + validate_tags(tags)
    playlists = ["course"] + ([f"part-{part:02d}"] if part is not None else [])
    item = {
        "id": vid, "number": n, "part": part, "part_name": part_name, "title": title,
        "publish_at": rfc3339(publish_utc),
        "publish_at_local": rfc3339(publish_utc, zone),
        "playlists": playlists,
        "description": full_desc,
        "tags": tags,
        "thumbnail": paths.rel(os.path.join(paths.thumbs, f"{vid}.png")),
        "captions": paths.rel(os.path.join(paths.out, f"{vid}.srt")),
        "asset_url": asset_url(vid),
        "size_bytes": size, "sha256": sha,
        "duration_seconds": duration_exact if duration_exact is not None else duration,
        "violations": errs,
    }
    return item


def build_plan(paths, cfg, start, gap_hours, zone, first=1, previous=None):
    src = load_sources(paths)
    problems = list(src["problems"])
    ids = [vid_name(i) for i in range(1, TOTAL_VIDEOS + 1)]
    if src["order"] != ids:
        missing = [v for v in ids if v not in src["meta"]]
        extra = [v for v in src["order"] if v not in ids]
        problems.append(f"youtube-metadata.md: expected V001 to V{TOTAL_VIDEOS:03d} in order; "
                        f"missing {missing[:10]}, unexpected {extra[:10]}")
    prev = {x["id"]: x for x in (previous or {}).get("videos", [])}
    items = []
    for vid in ids:
        n = vid_num(vid)
        if n < first:
            if vid not in prev:
                raise Fatal(f"--from needs an existing plan that contains {vid}")
            t = parse_rfc3339(prev[vid]["publish_at"])
        else:
            t = slot_time(start, gap_hours, n - first)
        if items and t <= parse_rfc3339(items[-1]["publish_at"]):
            raise Fatal(f"{vid} would be published at {fmt_local(t, zone)}, not after "
                        f"{items[-1]['id']} ({fmt_local(parse_rfc3339(items[-1]['publish_at']), zone)}). "
                        "Choose a later --start.")
        items.append(build_item(paths, cfg, src, vid, t, zone))
    titles = {}
    for it in items:
        titles.setdefault(it["title"], []).append(it["id"])
    for t, vs in titles.items():
        if len(vs) > 1 and t:
            for it in items:
                if it["id"] in vs:
                    it["violations"].append(f"title: the same as {[v for v in vs if v != it['id']]}; "
                                            "the duplicate guard needs unique titles")
    pls = playlist_defs(cfg, src["parts"])
    for p in pls:
        if len(p["title"]) > MAX_PLAYLIST_TITLE_CHARS or any(c in p["title"] for c in FORBIDDEN_CHARS):
            problems.append(f"playlist title not acceptable: {p['title']!r}")
    if len(src["parts"]) != 12 or sum(p["count"] for p in src["parts"].values()) != TOTAL_VIDEOS:
        problems.append("curriculum: the part summary does not describe 12 parts and 201 videos")
    return {
        "version": 1,
        "generated_at": rfc3339(now_utc()),
        "timezone": OWNER_TZ,
        "start_local": fmt_local(items[0] and parse_rfc3339(items[0]["publish_at"]), zone),
        "gap_hours": gap_hours,
        "settings": {k: cfg[k] for k in (
            "category_id", "language", "audio_language", "caption_language", "caption_name",
            "made_for_kids", "contains_synthetic_media", "notify_subscribers", "license",
            "embeddable", "public_stats_viewable", "playlist_privacy")},
        "playlists": pls,
        "problems": problems,
        "videos": items,
    }


def plan_violations(plan):
    out = [("plan", p) for p in plan.get("problems", [])]
    for it in plan["videos"]:
        out += [(it["id"], e) for e in it["violations"]]
    return out


def render_plan_md(plan, zone):
    v = plan["videos"]
    viol = plan_violations(plan)
    first, last = parse_rfc3339(v[0]["publish_at"]), parse_rfc3339(v[-1]["publish_at"])
    L = ["# YouTube release plan", "",
         f"Written by `tools/youtube_publish.py plan` on {plan.get('generated_at', '?')}. "
         "Do not edit by hand: run `plan` again.", "",
         f"- Videos: {len(v)}",
         f"- First publish time: {fmt_local(first, zone)} ({plan['timezone']})",
         f"- Last publish time: {fmt_local(last, zone)} ({plan['timezone']})",
         f"- Gap between videos: {plan['gap_hours']:g} hours",
         f"- Every video is uploaded as private and becomes public at its time.",
         f"- Category ID {plan['settings']['category_id']}, language "
         f"{plan['settings']['language']}, made for kids: "
         f"{'yes' if plan['settings']['made_for_kids'] else 'no'}, playlists created as "
         f"{plan['settings']['playlist_privacy']}.",
         f"- Violations of documented limits: {len(viol)}", ""]
    if viol:
        L += ["## Violations (nothing is uploaded for these videos until they are fixed)", ""]
        L += [f"- {who}: {msg}" for who, msg in viol] + [""]
    L += ["## Playlists", "", "| Key | Title | Videos |", "|---|---|---|"]
    for p in plan["playlists"]:
        n = sum(1 for it in v if p["key"] in it["playlists"])
        L.append(f"| {p['key']} | {p['title']} | {n} |")
    L += ["", "## Schedule", "",
          f"| No. | Publish time ({plan['timezone']}) | Publish time (UTC) | Title | Part | "
          "Title chars | Description bytes | Tag chars | Size MB |",
          "|---|---|---|---|---|---|---|---|---|"]
    for it in v:
        t = parse_rfc3339(it["publish_at"])
        mb = f"{it['size_bytes'] / 1e6:.1f}" if it.get("size_bytes") else "?"
        L.append(f"| {it['id']} | {fmt_local(t, zone)} | {it['publish_at']} | "
                 f"{it['title'].replace('|', chr(92) + '|')} | {it['part']} | {len(it['title'])} | "
                 f"{len(it['description'].encode('utf-8'))} | {tags_length(it['tags'])} | {mb} |")
    ex = v[0]
    L += ["", f"## Example: what is sent for {ex['id']}", "", "Title:", "", "```text", ex["title"], "```",
          "", "Description:", "", "```text", ex["description"], "```", "",
          "Tags:", "", "```text", ", ".join(ex["tags"]), "```", "",
          f"Thumbnail: `{ex['thumbnail']}`  ", f"Captions: `{ex['captions']}`  ",
          f"Video file: {ex['asset_url']}", "",
          "The same fields for every video are in `plan.json`.", ""]
    return "\n".join(L)


# --------------------------------------------------------------------------
# State and quota ledger
# --------------------------------------------------------------------------

class State:
    def __init__(self, path, read_only=False):
        self.path, self.read_only = path, read_only
        self.d = read_json(path) or {"version": 1, "channel": None, "playlists": {},
                                     "quota": {}, "videos": {}, "runs": []}

    def save(self):
        if self.read_only:
            return
        if not os.path.exists(self.path) and not (self.d["channel"] or self.d["videos"]
                                                  or self.d["playlists"] or self.d["quota"]):
            return   # nothing to remember yet
        write_json(self.path, self.d)

    def video(self, vid):
        return self.d["videos"].setdefault(vid, {"video_id": None, "url": None, "steps": {},
                                                 "done": False, "errors": []})

    def step(self, vid, name):
        return self.video(vid)["steps"].setdefault(name, {"status": "pending"})

    def set_step(self, vid, name, status, **extra):
        s = self.step(vid, name)
        s.update(status=status, at=rfc3339(now_utc()), **extra)
        if status == "ok":
            s.pop("error", None)
        self.save()

    def error(self, vid, step, message):
        v = self.video(vid)
        v["errors"] = (v["errors"] + [{"at": rfc3339(now_utc()), "step": step,
                                       "message": message[:500]}])[-10:]
        self.set_step(vid, step, "failed", error=message[:500])

    def uploaded(self, vid):
        return bool(self.d["videos"].get(vid, {}).get("video_id"))

    def is_done(self, vid):
        return bool(self.d["videos"].get(vid, {}).get("done"))


class Ledger:
    """Counts quota per Pacific-time day from the documented costs."""

    def __init__(self, state, daily_units=DEFAULT_DAILY_UNITS, daily_uploads=DEFAULT_DAILY_UPLOADS,
                 reserve=DEFAULT_RESERVE_UNITS, clock=now_utc):
        self.state, self.daily_units, self.daily_uploads = state, daily_units, daily_uploads
        self.reserve, self.clock = reserve, clock

    def day(self):
        return self.clock().astimezone(tz(QUOTA_TZ)).strftime("%Y-%m-%d")

    def today(self):
        return self.state.d["quota"].setdefault(self.day(), {"units": 0, "uploads": 0, "calls": {}})

    def units_left(self):
        return self.daily_units - self.reserve - self.today()["units"]

    def uploads_left(self):
        return self.daily_uploads - self.today()["uploads"]

    def can(self, units=0, uploads=0):
        return self.units_left() >= units and self.uploads_left() >= uploads

    def charge(self, name):
        t = self.today()
        if name in UPLOAD_BUCKET_CALLS:
            t["uploads"] += 1
        else:
            t["units"] += QUOTA_COST[name]
        t["calls"][name] = t["calls"].get(name, 0) + 1
        self.state.save()

    def require(self, name):
        if name in UPLOAD_BUCKET_CALLS:
            if self.uploads_left() < 1:
                raise StopRun(f"the daily videos.insert limit ({self.daily_uploads}) is used up. "
                              + self.rerun_hint())
        elif self.units_left() < QUOTA_COST[name]:
            raise StopRun(f"{name} costs {QUOTA_COST[name]} units and only {self.units_left()} "
                          f"are left today (limit {self.daily_units}, reserve {self.reserve}). "
                          + self.rerun_hint())

    def next_reset(self):
        z = tz(QUOTA_TZ)
        local = self.clock().astimezone(z)
        nxt = (local + dt.timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
        nxt = dt.datetime(nxt.year, nxt.month, nxt.day, tzinfo=z)  # correct offset on DST days
        return nxt

    def rerun_hint(self):
        r = self.next_reset()
        return (f"Quota resets at midnight Pacific Time: rerun after "
                f"{fmt_local(r + dt.timedelta(minutes=10), tz(OWNER_TZ))} {OWNER_TZ}.")


def video_cost(state, vid, playlist_keys):
    """Units (general bucket) and uploads still needed to finish one video."""
    st = state.d["videos"].get(vid, {})
    steps = st.get("steps", {})
    units, uploads = QUOTA_COST["videos.list"], 0
    if not st.get("video_id"):
        uploads = 1
    if steps.get("thumbnail", {}).get("status") != "ok":
        units += QUOTA_COST["thumbnails.set"]
    if steps.get("captions", {}).get("status") != "ok":
        units += QUOTA_COST["captions.insert"]
    done_pl = steps.get("playlists", {}).get("items", {})
    for k in playlist_keys:
        if done_pl.get(k, {}).get("status") != "ok":
            units += QUOTA_COST["playlistItems.insert"]
            if k not in state.d["playlists"]:
                units += QUOTA_COST["playlists.insert"]
    return units, uploads


# --------------------------------------------------------------------------
# HTTP
# --------------------------------------------------------------------------

class Http:
    """One request per connection, no redirects, plain http only to loopback."""

    def __init__(self, timeout=120):
        self.timeout = timeout

    def request(self, method, url, headers=None, body=None, body_len=None):
        u = urllib.parse.urlsplit(url)
        if u.scheme == "https":
            conn = http.client.HTTPSConnection(u.hostname, u.port, timeout=self.timeout)
        elif u.scheme == "http" and u.hostname in ("127.0.0.1", "localhost", "::1"):
            conn = http.client.HTTPConnection(u.hostname, u.port, timeout=self.timeout)
        else:
            raise Fatal(f"refusing a non-HTTPS request to {u.hostname}")
        h = dict(headers or {})
        if body is None:
            if method in ("POST", "PUT"):
                h["Content-Length"] = "0"
        elif isinstance(body, (bytes, bytearray)):
            h["Content-Length"] = str(len(body))
        else:
            h["Content-Length"] = str(body_len)
        try:
            conn.request(method, u.path + ("?" + u.query if u.query else ""), body=body, headers=h)
            r = conn.getresponse()
            data = r.read()
            return r.status, {k.lower(): v for k, v in r.getheaders()}, data
        finally:
            conn.close()


TRANSIENT_STATUS = (500, 502, 503, 504)
TRANSIENT_ERRORS = (OSError, http.client.HTTPException)
STOP_REASONS = ("quotaExceeded", "dailyLimitExceeded", "uploadLimitExceeded",
                "uploadRateLimitExceeded", "rateLimitExceeded", "userRateLimitExceeded")


def error_from(status, data):
    reason, message = "", ""
    try:
        e = json.loads(data.decode("utf-8"))["error"]
        if isinstance(e, dict):
            message = e.get("message", "")
            errs = e.get("errors") or [{}]
            reason = errs[0].get("reason", "") or e.get("status", "")
        else:  # token endpoint: {"error": "invalid_grant", "error_description": ...}
            reason = str(e)
            message = json.loads(data.decode("utf-8")).get("error_description", "")
    except (ValueError, KeyError, TypeError, AttributeError):
        message = data[:200].decode("utf-8", "replace")
    return HttpError(status, reason, message, data)


def backoff_delay(attempt, base=1.0, cap=64.0):
    return min(cap, base * (2 ** attempt)) + random.uniform(0, base)


# --------------------------------------------------------------------------
# OAuth 2.0 for a desktop app (loopback redirect with PKCE)
# --------------------------------------------------------------------------

def load_client(paths):
    c = read_json(paths.client_secret)
    if c is None:
        raise Fatal(f"the OAuth client file is missing: {paths.client_secret}\n"
                    "Create a Desktop OAuth client in Google Cloud and download its JSON "
                    "to that path (video/youtube/README.md, step 1).")
    c = c.get("installed")
    if not c or "client_id" not in c:
        raise Fatal(f"{paths.client_secret} is not a Desktop-app client file "
                    '(it must have a top-level "installed" key).')
    return {"client_id": c["client_id"], "client_secret": c.get("client_secret", "")}


def pkce_pair():
    verifier = secrets.token_urlsafe(64)[:96]   # 43..128 unreserved characters
    challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode("ascii")).digest())
    return verifier, challenge.rstrip(b"=").decode("ascii")


def build_auth_url(client_id, redirect_uri, state, challenge, scopes=SCOPES, auth_uri=AUTH_URI):
    q = {"client_id": client_id, "redirect_uri": redirect_uri, "response_type": "code",
         "scope": " ".join(scopes), "code_challenge": challenge,
         "code_challenge_method": "S256", "state": state}
    return auth_uri + "?" + urllib.parse.urlencode(q, quote_via=urllib.parse.quote)


class Tokens:
    def __init__(self, paths, http_=None, token_uri=TOKEN_URI, clock=time.time):
        self.paths, self.http, self.token_uri, self.clock = paths, http_ or Http(30), token_uri, clock
        self.d = None

    def load(self):
        self.d = read_json(self.paths.token)
        if not self.d or not self.d.get("refresh_token"):
            raise Fatal(f"no token yet ({self.paths.token}). Run:  tools/youtube_publish.py auth")
        st = os.stat(self.paths.token)
        if st.st_mode & 0o077:
            os.chmod(self.paths.token, 0o600)
        return self

    def save(self):
        os.makedirs(self.paths.config_dir, mode=0o700, exist_ok=True)
        write_json(self.paths.token, self.d, mode=0o600)

    def _post(self, form):
        status, _, data = self.http.request(
            "POST", self.token_uri,
            {"Content-Type": "application/x-www-form-urlencoded"},
            urllib.parse.urlencode(form).encode("ascii"))
        if status != 200:
            raise error_from(status, data)
        return json.loads(data.decode("utf-8"))

    def exchange(self, client, code, verifier, redirect_uri):
        r = self._post({"client_id": client["client_id"], "client_secret": client["client_secret"],
                        "code": code, "code_verifier": verifier,
                        "grant_type": "authorization_code", "redirect_uri": redirect_uri})
        if "refresh_token" not in r:
            raise Fatal("Google returned no refresh token; remove the app's access at "
                        "https://myaccount.google.com/permissions and run auth again.")
        self.d = {"refresh_token": r["refresh_token"], "access_token": r["access_token"],
                  "expires_at": self.clock() + int(r.get("expires_in", 0)),
                  "scope": r.get("scope", ""), "obtained_at": rfc3339(now_utc())}
        self.save()

    def refresh(self):
        client = load_client(self.paths)
        try:
            r = self._post({"client_id": client["client_id"],
                            "client_secret": client["client_secret"],
                            "grant_type": "refresh_token",
                            "refresh_token": self.d["refresh_token"]})
        except HttpError as e:
            if e.reason == "invalid_grant":
                raise Fatal("Google no longer accepts the stored refresh token (revoked, or "
                            "expired: 7 days if the consent screen is in Testing). "
                            "Run:  tools/youtube_publish.py auth")
            raise
        self.d["access_token"] = r["access_token"]
        self.d["expires_at"] = self.clock() + int(r.get("expires_in", 0))
        self.save()

    def access(self, force=False):
        if self.d is None:
            self.load()
        if force or not self.d.get("access_token") or self.clock() > self.d.get("expires_at", 0) - 120:
            self.refresh()
        return self.d["access_token"]


def run_auth(paths, dry_run=False, open_browser=True, timeout=300, out=print):
    if dry_run:
        try:
            cid = load_client(paths)["client_id"]
        except Fatal:
            cid = "CLIENT_ID_FROM_" + os.path.basename(paths.client_secret)
        _, ch = pkce_pair()
        out("DRY RUN. auth would open this page in the browser (state and challenge are "
            "new on every run), listen on a free port of 127.0.0.1 for the redirect, "
            f"exchange the code at {TOKEN_URI} and write {paths.token} with mode 600:")
        out("  " + build_auth_url(cid, "http://127.0.0.1:PORT", "RANDOM_STATE", ch))
        return 0
    client = load_client(paths)
    verifier, challenge = pkce_pair()
    state = secrets.token_urlsafe(24)
    result = {}

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            q = urllib.parse.parse_qs(urllib.parse.urlsplit(self.path).query)
            if "code" not in q and "error" not in q:
                self.send_response(404)
                self.end_headers()
                return
            ok = q.get("state", [""])[0] == state and "code" in q
            result.update(code=q.get("code", [None])[0], error=q.get("error", [None])[0],
                          state_ok=q.get("state", [""])[0] == state)
            body = ("<h2>Signed in. You can close this tab and return to the terminal.</h2>"
                    if ok else "<h2>Sign-in did not complete. See the terminal.</h2>").encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *a):   # never log the request line: it carries the code
            pass

    srv = http.server.HTTPServer(("127.0.0.1", 0), Handler)
    srv.timeout = 1
    redirect = f"http://127.0.0.1:{srv.server_address[1]}"
    url = build_auth_url(client["client_id"], redirect, state, challenge)
    out("Opening the Google consent page in your browser. Choose the Google account and "
        "the YouTube channel that should receive the videos.")
    out("If the browser does not open, paste this address into it:\n  " + url)
    if open_browser:
        with contextlib.suppress(Exception):
            webbrowser.open(url)
    deadline = time.time() + timeout
    try:
        while "state_ok" not in result and time.time() < deadline:
            srv.handle_request()
    finally:
        srv.server_close()
    if "state_ok" not in result:
        raise Fatal(f"no answer from the browser within {timeout} seconds; run auth again.")
    if not result["state_ok"]:
        raise Fatal("the answer did not carry the expected state value; nothing was stored.")
    if result["error"] or not result["code"]:
        raise Fatal(f"Google reported: {result['error'] or 'no code'}; nothing was stored.")
    Tokens(paths).exchange(client, result["code"], verifier, redirect)
    out(f"Token stored in {paths.token} (mode 600). Next:  tools/youtube_publish.py whoami")
    return 0


# --------------------------------------------------------------------------
# YouTube Data API client
# --------------------------------------------------------------------------

class Api:
    def __init__(self, tokens, ledger, http_=None, base=API_BASE, dry_run=False, out=print,
                 sleep=time.sleep, retries=5, backoff_base=1.0):
        self.tokens, self.ledger, self.http = tokens, ledger, http_ or Http()
        self.base, self.dry_run, self.out, self.sleep = base, dry_run, out, sleep
        self.retries, self.backoff_base = retries, backoff_base
        self.block_hook = None    # tests: called with the number of bytes sent so far

    # -- generic call ------------------------------------------------------
    def _headers(self, extra=None, force=False):
        h = {"Authorization": "Bearer " + self.tokens.access(force), "Accept": "application/json"}
        h.update(extra or {})
        return h

    def call(self, name, method, path, params, body=None, headers=None, describe=None,
             raw_response=False):
        url = self.base + path + "?" + urllib.parse.urlencode(params)
        if self.dry_run:
            self.out(f"  WOULD SEND {method} {url}")
            for k, v in (headers or {}).items():
                self.out(f"    {k}: {v}")
            if describe is not None:
                for line in describe.splitlines():
                    self.out("    " + line)
            cost = "1 call in the videos.insert bucket" if name in UPLOAD_BUCKET_CALLS \
                else f"{QUOTA_COST[name]} unit{'s' if QUOTA_COST[name] != 1 else ''}"
            self.out(f"    [{name}: {cost}]")
            return None
        refreshed = False
        attempt = 0
        while True:
            self.ledger.require(name)
            auth_headers = self._headers(headers)   # may stop here: no token, nothing sent
            self.ledger.charge(name)   # every request costs quota, even a failed one
            try:
                status, hdrs, data = self.http.request(method, url, auth_headers, body)
            except TRANSIENT_ERRORS as e:
                status, hdrs, data = None, {}, repr(e).encode()
            if status is not None and 200 <= status < 300:
                if raw_response:
                    return status, hdrs, data
                return json.loads(data.decode("utf-8")) if data.strip() else {}
            if status == 401 and not refreshed:
                refreshed = True
                self.tokens.access(force=True)
                continue
            err = error_from(status, data) if status is not None else None
            if err is not None and err.reason in STOP_REASONS and status in (403, 429):
                if err.reason in ("rateLimitExceeded", "userRateLimitExceeded") \
                        and attempt < self.retries:
                    pass  # short-term rate limit: back off below
                else:
                    raise StopRun(f"YouTube answered {status} {err.reason} for {name}: "
                                  f"{err.message} " + self.ledger.rerun_hint())
            elif status is not None and status not in TRANSIENT_STATUS:
                raise err
            attempt += 1
            if attempt > self.retries:
                raise err if err is not None else HttpError(0, "network", data.decode("utf-8", "replace"))
            delay = backoff_delay(attempt - 1, self.backoff_base)
            self.out(f"    {name}: temporary error ({status or 'network'}); "
                     f"retry {attempt}/{self.retries} in {delay:.0f} s")
            self.sleep(delay)

    # -- reads ---------------------------------------------------------------
    def my_channel(self):
        r = self.call("channels.list", "GET", "/youtube/v3/channels",
                      {"part": "snippet,contentDetails,status", "mine": "true"})
        if r is None:
            return None
        items = r.get("items", [])
        if not items:
            raise Fatal("this Google account has no YouTube channel (channels.list returned "
                        "nothing). Create the channel in YouTube first, then run auth again.")
        return items[0]

    def list_all(self, name, path, params, limit_pages=200):
        items, token = [], None
        for _ in range(limit_pages):
            p = dict(params, maxResults="50")
            if token:
                p["pageToken"] = token
            r = self.call(name, "GET", path, p)
            if r is None:
                return []
            items += r.get("items", [])
            token = r.get("nextPageToken")
            if not token:
                break
        return items

    def videos(self, ids, parts="snippet,status,contentDetails,processingDetails"):
        out = []
        for i in range(0, len(ids), 50):
            r = self.call("videos.list", "GET", "/youtube/v3/videos",
                          {"part": parts, "id": ",".join(ids[i:i + 50]), "maxResults": "50"})
            out += (r or {}).get("items", [])
        return out

    # -- writes --------------------------------------------------------------
    def start_upload(self, body, size, notify):
        raw = json.dumps(body, ensure_ascii=False).encode("utf-8")
        r = self.call(
            "videos.insert", "POST", "/upload/youtube/v3/videos",
            {"uploadType": "resumable", "part": "snippet,status",
             "notifySubscribers": "true" if notify else "false"},
            body=raw,
            headers={"Content-Type": "application/json; charset=UTF-8",
                     "X-Upload-Content-Length": str(size), "X-Upload-Content-Type": "video/mp4"},
            describe=json.dumps(body, indent=2, ensure_ascii=False), raw_response=True)
        if r is None:
            return None
        loc = r[1].get("location")
        if not loc:
            raise HttpError(r[0], "noLocation", "the upload session address is missing")
        return loc

    def _file_blocks(self, path, start, length, total):
        sent = 0
        next_mark = 0
        with open(path, "rb") as f:
            f.seek(start)
            while sent < length:
                block = f.read(min(1 << 20, length - sent))
                if not block:
                    raise OSError("the file is shorter than expected")
                sent += len(block)
                if self.block_hook:
                    self.block_hook(start + sent)
                pct = (start + sent) * 100 // total
                if pct >= next_mark:
                    self.out(f"    uploaded {pct}% ({(start + sent) / 1e6:.0f} of {total / 1e6:.0f} MB)")
                    next_mark = pct - pct % 20 + 20
                yield block

    def upload_offset(self, session, total):
        """Ask the server how much it has. Returns ('done', resource) or ('at', offset)."""
        status, hdrs, data = self.http.request(
            "PUT", session, self._headers({"Content-Range": f"bytes */{total}"}))
        if status in (200, 201):
            return "done", json.loads(data.decode("utf-8"))
        if status == 308:
            m = re.fullmatch(r"bytes=0-(\d+)", hdrs.get("range", "").strip())
            return "at", (int(m.group(1)) + 1 if m else 0)
        if status == 404:
            raise SessionExpired()
        if status in TRANSIENT_STATUS:
            raise http.client.HTTPException(f"status {status}")
        raise error_from(status, data)

    def send_file(self, session, path, total, start=None, chunk=None):
        """Send the file to a resumable session; resume after interruptions."""
        failures = 0
        while True:
            try:
                if start is None:
                    kind, val = self.upload_offset(session, total)
                    if kind == "done":
                        return val
                    start = val
                    if start:
                        self.out(f"    resuming at byte {start} of {total}")
                length = min(chunk, total - start) if chunk else total - start
                headers = {"Content-Type": "video/mp4"}
                if start or chunk:
                    headers["Content-Range"] = f"bytes {start}-{start + length - 1}/{total}"
                status, hdrs, data = self.http.request(
                    "PUT", session, self._headers(headers),
                    self._file_blocks(path, start, length, total), body_len=length)
            except TRANSIENT_ERRORS as e:
                status, hdrs, data = None, {}, repr(e).encode()
            if status in (200, 201):
                return json.loads(data.decode("utf-8"))
            if status == 308:
                m = re.fullmatch(r"bytes=0-(\d+)", hdrs.get("range", "").strip())
                new = int(m.group(1)) + 1 if m else 0
                if new > (start or 0):
                    failures = 0
                start = new
                continue
            if status == 404:
                raise SessionExpired()
            if status == 401:
                self.tokens.access(force=True)
                start = None
                failures += 1
                if failures > self.retries:
                    raise error_from(status, data)
                continue
            if status is not None and status not in TRANSIENT_STATUS:
                err = error_from(status, data)
                if err.reason in STOP_REASONS:
                    raise StopRun(f"YouTube answered {status} {err.reason} during the upload: "
                                  f"{err.message} " + self.ledger.rerun_hint())
                raise err
            failures += 1
            if failures > self.retries:
                raise HttpError(status or 0, "uploadInterrupted",
                                "the upload kept failing; the session is kept, a rerun resumes it")
            delay = backoff_delay(failures - 1, self.backoff_base)
            self.out(f"    upload interrupted ({status or 'network'}); "
                     f"retry {failures}/{self.retries} in {delay:.0f} s")
            self.sleep(delay)
            start = None   # always ask the server where to continue

    def set_thumbnail(self, video_id, path):
        with open(path, "rb") as f:
            data = f.read()
        return self.call("thumbnails.set", "POST", "/upload/youtube/v3/thumbnails/set",
                         {"videoId": video_id, "uploadType": "media"}, body=data,
                         headers={"Content-Type": "image/png"},
                         describe=f"<{len(data)} bytes of {os.path.basename(path)}>")

    def insert_caption(self, video_id, path, language, name):
        meta = {"snippet": {"videoId": video_id, "language": language, "name": name,
                            "isDraft": False}}
        with open(path, "rb") as f:
            data = f.read()
        b = "gm" + secrets.token_hex(16)
        body = (f"--{b}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n"
                f"{json.dumps(meta)}\r\n--{b}\r\nContent-Type: application/octet-stream\r\n\r\n"
                ).encode("utf-8") + data + f"\r\n--{b}--\r\n".encode("ascii")
        return self.call("captions.insert", "POST", "/upload/youtube/v3/captions",
                         {"uploadType": "multipart", "part": "snippet"}, body=body,
                         headers={"Content-Type": f"multipart/related; boundary={b}"},
                         describe=json.dumps(meta) + f"\n<{len(data)} bytes of {os.path.basename(path)}>")

    def create_playlist(self, title, description, privacy, language):
        body = {"snippet": {"title": title, "description": description,
                            "defaultLanguage": language},
                "status": {"privacyStatus": privacy}}
        return self.call("playlists.insert", "POST", "/youtube/v3/playlists",
                         {"part": "snippet,status"}, body=json.dumps(body).encode("utf-8"),
                         headers={"Content-Type": "application/json; charset=UTF-8"},
                         describe=json.dumps(body, indent=2, ensure_ascii=False))

    def add_to_playlist(self, playlist_id, video_id):
        body = {"snippet": {"playlistId": playlist_id,
                            "resourceId": {"kind": "youtube#video", "videoId": video_id}}}
        return self.call("playlistItems.insert", "POST", "/youtube/v3/playlistItems",
                         {"part": "snippet"}, body=json.dumps(body).encode("utf-8"),
                         headers={"Content-Type": "application/json; charset=UTF-8"},
                         describe=json.dumps(body))

    def update_status(self, video_id, status_body):
        body = {"id": video_id, "status": status_body}
        return self.call("videos.update", "PUT", "/youtube/v3/videos", {"part": "status"},
                         body=json.dumps(body).encode("utf-8"),
                         headers={"Content-Type": "application/json; charset=UTF-8"},
                         describe=json.dumps(body, indent=2))


def insert_body(item, settings):
    snippet = {"title": item["title"], "description": item["description"], "tags": item["tags"],
               "categoryId": str(settings["category_id"]),
               "defaultLanguage": settings["language"],
               "defaultAudioLanguage": settings["audio_language"]}
    status = {"privacyStatus": "private", "publishAt": item["publish_at"],
              "selfDeclaredMadeForKids": bool(settings["made_for_kids"]),
              "license": settings["license"], "embeddable": bool(settings["embeddable"]),
              "publicStatsViewable": bool(settings["public_stats_viewable"])}
    if settings.get("contains_synthetic_media") is not None:
        status["containsSyntheticMedia"] = bool(settings["contains_synthetic_media"])
    return {"snippet": snippet, "status": status}


# --------------------------------------------------------------------------
# Getting the MP4 (local copy or GitHub release asset)
# --------------------------------------------------------------------------

ALLOWED_DOWNLOAD_HOSTS = ("github.com", "githubusercontent.com")


def host_allowed(url):
    h = urllib.parse.urlsplit(url).hostname or ""
    return any(h == a or h.endswith("." + a) for a in ALLOWED_DOWNLOAD_HOSTS)


def head_size(url, timeout=30):
    req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": "git-mastery-youtube"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        if not host_allowed(r.geturl()):
            raise OSError(f"redirected to an unexpected host: {urllib.parse.urlsplit(r.geturl()).hostname}")
        return int(r.headers.get("Content-Length", "-1"))


def download(url, dest, expected_size, out=print, timeout=60):
    """Download with resume into dest + '.part', then rename. Size is checked."""
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    part = dest + ".part"
    for attempt in range(6):
        have = os.path.getsize(part) if os.path.exists(part) else 0
        if expected_size and have > expected_size:
            os.unlink(part)
            have = 0
        if expected_size and have == expected_size:
            break
        headers = {"User-Agent": "git-mastery-youtube"}
        if have:
            headers["Range"] = f"bytes={have}-"
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=headers),
                                        timeout=timeout) as r:
                if not host_allowed(r.geturl()):
                    raise Fatal(f"download redirected to an unexpected host for {url}")
                mode = "ab" if have and r.status == 206 else "wb"
                with open(part, mode) as f:
                    shutil.copyfileobj(r, f, 1 << 20)
        except (urllib.error.URLError, OSError, http.client.HTTPException) as e:
            if isinstance(e, urllib.error.HTTPError) and e.code in (403, 404):
                raise Fatal(f"GitHub answered {e.code} for {url}")
            delay = backoff_delay(attempt)
            out(f"    download interrupted ({e}); retry in {delay:.0f} s")
            time.sleep(delay)
            continue
        if not expected_size or os.path.getsize(part) == expected_size:
            break
    else:
        raise Fatal(f"could not download {url} completely")
    os.replace(part, dest)
    return dest


# --------------------------------------------------------------------------
# The upload pipeline
# --------------------------------------------------------------------------

class Uploader:
    def __init__(self, paths, plan, state, api, ledger, cfg=None, out=print, clock=now_utc,
                 fetch=None, lead_minutes=30, chunk=None, verify_wait=0, sleep=time.sleep,
                 adopt=False):
        self.paths, self.plan, self.state, self.api, self.ledger = paths, plan, state, api, ledger
        self.out, self.clock, self.lead = out, clock, dt.timedelta(minutes=lead_minutes)
        self.fetch = fetch or self._fetch
        self.chunk, self.verify_wait, self.sleep, self.adopt = chunk, verify_wait, sleep, adopt
        self.settings = plan["settings"]
        self.items = {it["id"]: it for it in plan["videos"]}
        self.pl_defs = {p["key"]: p for p in plan["playlists"]}
        self.sessions = read_json(paths.sessions, {}) or {}
        self.channel = None
        self.existing_titles = None
        self.downloaded = set()

    # -- helpers -------------------------------------------------------------
    def _save_sessions(self):
        os.makedirs(self.paths.config_dir, mode=0o700, exist_ok=True)
        write_json(self.paths.sessions, self.sessions, mode=0o600)

    def _fetch(self, item):
        """Return (path, is_temporary)."""
        vid = item["id"]
        local = os.path.join(self.paths.out, f"{vid}.mp4")
        size = item.get("size_bytes")
        if os.path.exists(local) and (not size or os.path.getsize(local) == size):
            return local, False
        dest = os.path.join(self.paths.cache_dir, f"{vid}.mp4")
        if not (os.path.exists(dest) and size and os.path.getsize(dest) == size):
            self.out(f"  downloading {item['asset_url']}")
            download(item["asset_url"], dest, size, self.out)
        return dest, True

    def _check_file(self, item, path):
        size = os.path.getsize(path)
        if item.get("size_bytes") and size != item["size_bytes"]:
            raise Fatal(f"{item['id']}: file size {size} differs from the QC record {item['size_bytes']}")
        if size > MAX_VIDEO_BYTES:
            raise Fatal(f"{item['id']}: larger than 256 GB")
        if item.get("sha256") and sha256_file(path) != item["sha256"]:
            raise Fatal(f"{item['id']}: SHA-256 differs from the QC record; the file is not the checked one")
        return size

    def channel_titles(self):
        """Titles already on the channel -> video ID (the second duplicate guard)."""
        if self.existing_titles is None:
            pl = self.channel["contentDetails"]["relatedPlaylists"]["uploads"]
            items = self.api.list_all("playlistItems.list", "/youtube/v3/playlistItems",
                                      {"part": "snippet", "playlistId": pl})
            self.existing_titles = {}
            for it in items:
                sn = it.get("snippet", {})
                self.existing_titles.setdefault(sn.get("title"), sn.get("resourceId", {}).get("videoId"))
        return self.existing_titles

    def ensure_playlist(self, key):
        st = self.state.d["playlists"]
        if key in st:
            return st[key]["id"]
        d = self.pl_defs[key]
        if not hasattr(self, "_mine"):
            self._mine = self.api.list_all("playlists.list", "/youtube/v3/playlists",
                                           {"part": "snippet", "mine": "true"})
        for p in self._mine:
            if p.get("snippet", {}).get("title") == d["title"]:
                st[key] = {"id": p["id"], "title": d["title"], "found_existing": True,
                           "at": rfc3339(self.clock())}
                self.state.save()
                self.out(f"  playlist exists already: {d['title']}")
                return p["id"]
        r = self.api.create_playlist(d["title"], d["description"],
                                     self.settings["playlist_privacy"], self.settings["language"])
        st[key] = {"id": r["id"], "title": d["title"], "at": rfc3339(self.clock())}
        self.state.save()
        self.out(f"  playlist created: {d['title']}")
        return r["id"]

    # -- steps ---------------------------------------------------------------
    def step_insert(self, item):
        vid = item["id"]
        st = self.state.video(vid)
        if st.get("video_id"):
            return st["video_id"]
        resource, path, temp = None, None, False
        sess = self.sessions.get(vid)
        if sess:   # an earlier run started this upload: never start a second one blindly
            try:
                kind, val = self.api.upload_offset(sess["uri"], sess["size"])
                if kind == "done":
                    resource = val
                    self.out("  the earlier upload session had already completed")
                else:
                    path, temp = self.fetch(item)
                    self._check_file(item, path)
                    self.out(f"  continuing the earlier upload session at byte {val}")
                    resource = self.api.send_file(sess["uri"], path, sess["size"], val, self.chunk)
            except SessionExpired:
                self.out("  the earlier upload session expired; checking the channel before a new one")
                self.sessions.pop(vid, None)
                self._save_sessions()
                self.existing_titles = None
        if resource is None:
            found = self.channel_titles().get(item["title"])
            if found:
                if not self.adopt:
                    raise Fatal(f"{vid}: the channel already has a video with this exact title "
                                f"(https://youtu.be/{found}) but state.json has no record of it. "
                                "Nothing was uploaded. If that video is this one, rerun with "
                                "--adopt to record it; otherwise delete or rename it in YouTube Studio.")
                resource = {"id": found, "adopted": True}
                self.out(f"  adopted the existing video {found}")
        if resource is None:
            if path is None:
                path, temp = self.fetch(item)
            size = self._check_file(item, path)
            self.ledger.require("videos.insert")
            uri = self.api.start_upload(insert_body(item, self.settings), size,
                                        self.settings["notify_subscribers"])
            self.sessions[vid] = {"uri": uri, "size": size, "started": rfc3339(self.clock())}
            self._save_sessions()
            self.state.set_step(vid, "insert", "started", bytes=size)
            try:
                resource = self.api.send_file(uri, path, size, 0, self.chunk)
            except SessionExpired:
                self.sessions.pop(vid, None)
                self._save_sessions()
                raise HttpError(404, "sessionExpired", "the upload session expired; rerun")
        st["video_id"] = resource["id"]
        st["url"] = "https://youtu.be/" + resource["id"]
        st["publish_at"] = item["publish_at"]
        st["title"] = item["title"]
        self.state.set_step(vid, "insert", "ok", adopted=bool(resource.get("adopted")))
        self.sessions.pop(vid, None)
        self._save_sessions()
        if self.existing_titles is not None:
            self.existing_titles[item["title"]] = resource["id"]
        if temp and path and os.path.exists(path):
            os.unlink(path)   # only a file this tool downloaded
        self.out(f"  uploaded: {st['url']}")
        return resource["id"]

    def step_thumbnail(self, item, video_id):
        self.api.set_thumbnail(video_id, os.path.join(self.paths.root, item["thumbnail"]))
        self.state.set_step(item["id"], "thumbnail", "ok")
        self.out("  thumbnail set")

    def step_captions(self, item, video_id):
        vid = item["id"]
        try:
            r = self.api.insert_caption(video_id, os.path.join(self.paths.root, item["captions"]),
                                        self.settings["caption_language"],
                                        self.settings["caption_name"])
            self.state.set_step(vid, "captions", "ok", caption_id=r.get("id"))
        except HttpError as e:
            if e.status == 409 and e.reason == "captionExists":
                self.state.set_step(vid, "captions", "ok", note="the track existed already")
            else:
                raise
        self.out("  captions uploaded")

    def step_playlists(self, item, video_id):
        vid = item["id"]
        s = self.state.step(vid, "playlists")
        items = s.setdefault("items", {})
        for key in item["playlists"]:
            if items.get(key, {}).get("status") == "ok":
                continue
            pid = self.ensure_playlist(key)
            if items.get(key, {}).get("status") == "started":
                # A run stopped between the request and the record: look before adding again.
                got = self.api.list_all("playlistItems.list", "/youtube/v3/playlistItems",
                                        {"part": "id", "playlistId": pid, "videoId": video_id})
                if got:
                    items[key] = {"status": "ok", "item_id": got[0]["id"]}
                    self.state.save()
                    continue
            items[key] = {"status": "started"}
            self.state.save()
            r = self.api.add_to_playlist(pid, video_id)
            items[key] = {"status": "ok", "item_id": r.get("id")}
            self.state.save()
        self.state.set_step(vid, "playlists", "ok")
        self.out("  added to playlists: " + ", ".join(item["playlists"]))

    def check_resource(self, item, res):
        """Compare the API's video resource with the plan right after the upload.
        Returns (problems, still_processing)."""
        probs, sn, stt = [], res.get("snippet", {}), res.get("status", {})
        if sn.get("title") != item["title"]:
            probs.append(f"title is {sn.get('title')!r}")
        if stt.get("privacyStatus") != "private":
            probs.append(f"privacyStatus is {stt.get('privacyStatus')!r}, expected 'private'")
        pa = stt.get("publishAt")
        if not pa or parse_rfc3339(pa) != parse_rfc3339(item["publish_at"]):
            probs.append(f"publishAt is {pa!r}, expected {item['publish_at']}")
        up = stt.get("uploadStatus")
        if up in ("failed", "rejected", "deleted"):
            probs.append(f"uploadStatus is {up} ({stt.get('failureReason') or stt.get('rejectionReason')})")
        proc = res.get("processingDetails", {}).get("processingStatus")
        if proc in ("failed", "terminated"):
            probs.append(f"processingStatus is {proc}")
        dur = parse_iso_duration(res.get("contentDetails", {}).get("duration"))
        processing = up == "uploaded" or proc == "processing" or not dur
        if dur and item.get("duration_seconds") and abs(dur - item["duration_seconds"]) > 3:
            probs.append(f"duration is {dur} s, QC measured {item['duration_seconds']:.0f} s")
        return probs, processing

    def step_verify(self, item, video_id):
        vid = item["id"]
        waited = 0
        while True:
            res = self.api.videos([video_id])
            if not res:
                self.state.error(vid, "verify", "videos.list does not return the video")
                return False
            probs, processing = self.check_resource(item, res[0])
            if probs:
                self.state.error(vid, "verify", "; ".join(probs))
                self.out("  VERIFY FAILED: " + "; ".join(probs))
                return False
            if not processing:
                self.state.set_step(vid, "verify", "ok")
                self.out("  verified: private, scheduled, processed, duration matches")
                return True
            if waited >= self.verify_wait:
                self.state.set_step(vid, "verify", "processing")
                self.out("  YouTube is still processing; the next run checks again")
                return False
            self.sleep(20)
            waited += 20

    # -- one video -------------------------------------------------------------
    def process(self, item):
        vid = item["id"]
        st = self.state.video(vid)
        steps = st["steps"]
        video_id = self.step_insert(item)
        ok = True
        for name, fn in (("thumbnail", self.step_thumbnail), ("captions", self.step_captions),
                         ("playlists", self.step_playlists)):
            if steps.get(name, {}).get("status") == "ok":
                continue
            try:
                fn(item, video_id)
            except HttpError as e:
                ok = False
                self.state.error(vid, name, str(e))
                self.out(f"  {name} FAILED: {e}  (the next run tries this step again)")
        verified = self.step_verify(item, video_id)
        st["done"] = bool(ok and verified)
        self.state.save()
        return st["done"]

    # -- the run ---------------------------------------------------------------
    def past_slot(self, item):
        return parse_rfc3339(item["publish_at"]) < self.clock() + self.lead

    def run(self, selection, expected_channel, reschedule=False):
        ch = self.api.my_channel()
        if ch["id"] != expected_channel:
            raise Fatal(f"the token belongs to channel {ch['snippet']['title']} ({ch['id']}), "
                        f"not to the confirmed channel {expected_channel}. Nothing was uploaded.")
        self.channel = ch
        self.out(f"Channel: {ch['snippet']['title']} ({ch['id']})")
        summary = {"done": [], "skipped_past": [], "skipped_violation": [], "failed": [],
                   "pending": [], "stopped": None}
        if reschedule:
            moved = reschedule_pending(self.plan, self.state, self.clock(), self.lead)
            if moved:
                write_json(self.paths.plan, self.plan)
                atomic_write(self.paths.plan_md, render_plan_md(self.plan, tz(OWNER_TZ)))
                self.out(f"Rescheduled {moved} not-yet-uploaded videos; plan.json and PLAN.md updated.")
        for vid in selection:
            item = self.items[vid]
            if self.state.is_done(vid):
                continue
            if item["violations"]:
                summary["skipped_violation"].append(vid)
                self.out(f"{vid}: SKIPPED, the plan lists violations: {item['violations'][0]}")
                continue
            if not self.state.uploaded(vid) and self.past_slot(item):
                summary["skipped_past"].append(vid)
                self.out(f"{vid}: SKIPPED, its publish time {item['publish_at_local']} is in the past "
                         f"or less than {int(self.lead.total_seconds() // 60)} minutes away. "
                         "Use --reschedule, or plan --from.")
                continue
            units, uploads = video_cost(self.state, vid, item["playlists"])
            if not self.ledger.can(units, uploads):
                summary["stopped"] = (f"{vid} needs {units} units and {uploads} upload call(s); left "
                                      f"today: {self.ledger.units_left()} units, "
                                      f"{self.ledger.uploads_left()} uploads. " + self.ledger.rerun_hint())
                break
            self.out(f"{vid}: {item['title']}  ->  {item['publish_at_local']}")
            try:
                done = self.process(item)
                (summary["done"] if done else summary["pending"]).append(vid)
            except StopRun as e:
                summary["stopped"] = str(e)
                break
            except HttpError as e:
                step = next((n for n in STEP_NAMES
                             if self.state.video(vid)["steps"].get(n, {}).get("status") != "ok"), "insert")
                self.state.error(vid, step, str(e))
                summary["failed"].append(vid)
                self.out(f"  FAILED at {step}: {e}")
                if step == "insert" and e.status in (400, 401, 403):
                    summary["stopped"] = ("the upload itself was refused; fix the cause before "
                                          "more videos are tried.")
                    break
            except TRANSIENT_ERRORS as e:
                summary["failed"].append(vid)
                summary["stopped"] = (f"network problem at {vid} ({e!r}); nothing is lost, "
                                      "run the same command again.")
                self.out("  " + summary["stopped"])
                break
        return summary


def reschedule_pending(plan, state, now, lead):
    """Move every not-yet-uploaded video later by a whole number of gaps so that
    the first of them is at least `lead` in the future. Order is kept."""
    pending = [it for it in plan["videos"] if not state.uploaded(it["id"])]
    if not pending:
        return 0
    first = parse_rfc3339(pending[0]["publish_at"])
    target = now + lead
    if first >= target:
        return 0
    gap = dt.timedelta(seconds=round(plan["gap_hours"] * 3600))
    k = math.ceil((target - first) / gap)
    zone = tz(plan.get("timezone", OWNER_TZ))
    for it in pending:
        t = parse_rfc3339(it["publish_at"]) + k * gap
        it["publish_at"] = rfc3339(t)
        it["publish_at_local"] = rfc3339(t, zone)
    return len(pending)


# --------------------------------------------------------------------------
# Commands
# --------------------------------------------------------------------------

def need_plan(paths):
    plan = read_json(paths.plan)
    if not plan:
        raise Fatal('no plan yet. Run:  tools/youtube_publish.py plan --start "YYYY-MM-DD HH:MM"')
    return plan


def select_videos(args, plan, state):
    ids = [it["id"] for it in plan["videos"]]
    if getattr(args, "only", None):
        want = [v.upper() for v in args.only]
        bad = [v for v in want if v not in ids]
        if bad:
            raise Fatal(f"not in the plan: {bad}")
        return [v for v in ids if v in want]
    pending = [v for v in ids if not state.is_done(v)]
    if getattr(args, "next", None):
        return pending[:args.next]
    if getattr(args, "all", False):
        return pending
    raise Fatal("say which videos: --only V001 [V002 ...], --next N or --all")


def expected_channel(args, state):
    cid = getattr(args, "channel_id", None) or (state.d.get("channel") or {}).get("id")
    if not cid:
        raise Fatal("no confirmed channel. Run `whoami`, check the channel it shows, then "
                    "`whoami --confirm` (or pass --channel-id UC... to this command).")
    return cid


@contextlib.contextmanager
def run_lock(paths):
    import fcntl
    os.makedirs(paths.yt, exist_ok=True)
    f = open(paths.lock, "w")
    try:
        try:
            fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            raise Fatal("another youtube_publish.py run holds the lock; wait for it to finish.")
        yield
    finally:
        f.close()


def make_api(paths, state, args, out=print):
    ledger = Ledger(state, args.daily_units, args.daily_uploads, args.reserve_units)
    return Api(Tokens(paths), ledger, dry_run=False, out=out), ledger


def cmd_plan(paths, args, out=print):
    zone = tz(OWNER_TZ)
    cfg = load_config(paths)
    previous = read_json(paths.plan)
    first = vid_num(args.from_video.upper()) if args.from_video else 1
    if not 1 <= first <= TOTAL_VIDEOS:
        raise Fatal("--from must be V001 to V201")
    if args.gap_hours <= 0:
        raise Fatal("--gap-hours must be positive")
    start = parse_local_start(args.start, zone)
    plan = build_plan(paths, cfg, start, args.gap_hours, zone, first, previous)
    state = State(paths.state, read_only=True)
    moved = [it["id"] for it in plan["videos"] if state.uploaded(it["id"])
             and state.d["videos"][it["id"]].get("publish_at")
             and parse_rfc3339(state.d["videos"][it["id"]]["publish_at"]) != parse_rfc3339(it["publish_at"])]
    viol = plan_violations(plan)
    v = plan["videos"]
    out(f"{len(v)} videos, {fmt_local(parse_rfc3339(v[0]['publish_at']), zone)} to "
        f"{fmt_local(parse_rfc3339(v[-1]['publish_at']), zone)} {OWNER_TZ}, every "
        f"{args.gap_hours:g} hours; {len(plan['playlists'])} playlists.")
    out(f"Longest title {max(len(i['title']) for i in v)} of {MAX_TITLE_CHARS} characters; largest "
        f"description {max(len(i['description'].encode()) for i in v)} of {MAX_DESCRIPTION_BYTES} bytes; "
        f"largest tag set {max(tags_length(i['tags']) for i in v)} of {MAX_TAGS_CHARS} characters.")
    if start < dt.datetime.now(zone):
        out("WARNING: the first publish time is in the past; upload will skip such videos.")
    for who, msg in viol:
        out(f"VIOLATION {who}: {msg}")
    out(f"Violations: {len(viol)}")
    if moved:
        out(f"NOTE: {len(moved)} already-uploaded videos get a new time in this plan "
            f"({moved[0]} to {moved[-1]}). Run `retime` to apply it on YouTube.")
    if args.dry_run:
        out("DRY RUN: plan.json and PLAN.md were not written.")
    else:
        write_json(paths.plan, plan)
        atomic_write(paths.plan_md, render_plan_md(plan, zone))
        out(f"Wrote {paths.rel(paths.plan)} and {paths.rel(paths.plan_md)}")
    return 1 if viol else 0


def cmd_check(paths, args, out=print):
    plan = need_plan(paths)
    src = load_sources(paths)
    problems = {}

    def bad(vid, msg):
        problems.setdefault(vid, []).append(msg)

    for p in plan.get("problems", []) + src["problems"]:
        bad("plan", p)
    for it in plan["videos"]:
        vid = it["id"]
        for e in it["violations"]:
            bad(vid, e)
        m = src["meta"].get(vid, {})
        if m.get("title") != it["title"]:
            bad(vid, "metadata: the title changed since the plan was built; run plan again")
        if m.get("description") is None or not it["description"].startswith(m.get("description", "\0").strip()):
            bad(vid, "metadata: the description changed since the plan was built; run plan again")
        td = src["tdata"].get(vid)
        if not td:
            bad(vid, "thumbnail-data.json has no entry")
        elif td.get("youtube_title") != m.get("title") or td.get("description") != m.get("description"):
            bad(vid, "youtube-metadata.md and thumbnail-data.json disagree")
        tp = os.path.join(paths.root, it["thumbnail"])
        if not os.path.exists(tp):
            bad(vid, f"thumbnail: {it['thumbnail']} is missing")
        else:
            size, dims = os.path.getsize(tp), png_size(tp)
            if size > MAX_THUMBNAIL_BYTES:
                bad(vid, f"thumbnail: {size} bytes, the API limit is 50 MB")
            elif size > WARN_THUMBNAIL_BYTES:
                bad(vid, f"thumbnail: {size} bytes, above the 2 MB the Help Center gives for mobile")
            if dims is None:
                bad(vid, "thumbnail: not a PNG file")
            elif dims[0] < MIN_THUMBNAIL_WIDTH or dims[0] * 9 != dims[1] * 16:
                bad(vid, f"thumbnail: {dims[0]}x{dims[1]}, expected 16:9 and at least 640 wide")
        sp = os.path.join(paths.root, it["captions"])
        if not os.path.exists(sp):
            bad(vid, f"captions: {it['captions']} is missing")
        else:
            try:
                with open(sp, encoding="utf-8") as f:
                    cues, errs = parse_srt(f.read())
            except UnicodeDecodeError:
                cues, errs = [], ["not UTF-8"]
            for e in errs[:3]:
                bad(vid, f"captions: {e}")
            if os.path.getsize(sp) > MAX_CAPTION_BYTES:
                bad(vid, "captions: larger than 100 MB")
            if cues and it.get("duration_seconds") and cues[-1][1] / 1000 > it["duration_seconds"] + 2:
                bad(vid, "captions: the last cue ends after the end of the video")
        qc = src["qc"].get(vid)
        if not qc:
            bad(vid, "QC: no row in QC-FINAL.md")
        elif qc["status"] != "PASS":
            bad(vid, f"QC: status is {qc['status']}")
        if not it.get("size_bytes"):
            bad(vid, "QC: no file size on record (qc/VNNN.qc.json)")
        if it.get("duration_seconds") and it["duration_seconds"] > 12 * 3600:
            bad(vid, "longer than 12 hours")
    if args.dry_run:
        out(f"DRY RUN: would send {len(plan['videos'])} HTTP HEAD requests to GitHub, e.g. "
            f"{plan['videos'][0]['asset_url']}")
    elif args.no_network:
        out("Release assets were NOT checked (--no-network).")
    else:
        def head(it):
            for attempt in range(3):
                try:
                    return it["id"], head_size(it["asset_url"]), None
                except (urllib.error.URLError, OSError, ValueError) as e:
                    err = str(e)
                    time.sleep(1 + attempt)
            return it["id"], None, err
        with concurrent.futures.ThreadPoolExecutor(8) as ex:
            results = list(ex.map(head, plan["videos"]))
        sizes = {it["id"]: it.get("size_bytes") for it in plan["videos"]}
        for vid, size, err in results:
            if err:
                bad(vid, f"release asset: {err}")
            elif sizes[vid] and size != sizes[vid]:
                bad(vid, f"release asset: {size} bytes on GitHub, QC recorded {sizes[vid]}")
        total = sum(s for _, s, e in results if s and not e)
        out(f"Release assets answered: {sum(1 for _, s, e in results if not e)} of "
            f"{len(results)}, {total / 1e9:.2f} GB in total.")
    n_bad = len([v for v in problems if v != "plan"])
    for vid in sorted(problems):
        for msg in problems[vid]:
            out(f"PROBLEM {vid}: {msg}")
    out(f"check: {len(plan['videos']) - n_bad} of {len(plan['videos'])} videos ready, "
        f"{sum(len(v) for v in problems.values())} problems.")
    return 1 if problems else 0


def cmd_whoami(paths, args, out=print):
    state = State(paths.state, read_only=args.dry_run)
    api, _ = make_api(paths, state, args, out)
    api.dry_run = args.dry_run
    cfg = load_config(paths)
    ch = api.my_channel()
    if args.dry_run:
        api.call("videoCategories.list", "GET", "/youtube/v3/videoCategories",
                 {"part": "snippet", "regionCode": cfg["region_code"]})
        return 0
    out(f"Channel title : {ch['snippet']['title']}")
    out(f"Channel ID    : {ch['id']}")
    if ch["snippet"].get("customUrl"):
        out(f"Handle        : {ch['snippet']['customUrl']}")
    lu = ch.get("status", {}).get("longUploadsStatus")
    plan = read_json(paths.plan) or {"videos": []}
    n_long = sum(1 for it in plan["videos"] if (it.get("duration_seconds") or 0) > 15 * 60)
    out(f"Videos longer than 15 minutes: {lu or 'unknown'}"
        + ("" if lu == "allowed" else "   <-- verify the channel by phone first: "
           f"https://www.youtube.com/verify ({n_long} videos of the plan are longer than 15 minutes)"))
    try:
        cats = api.call("videoCategories.list", "GET", "/youtube/v3/videoCategories",
                        {"part": "snippet", "regionCode": cfg["region_code"]})
        name = {c["id"]: c["snippet"]["title"] for c in cats.get("items", [])}.get(str(cfg["category_id"]))
        out(f"Category {cfg['category_id']}  : {name or 'NOT A VALID CATEGORY ID in ' + cfg['region_code']}")
    except HttpError as e:
        out(f"Category check failed: {e}")
    stored = (state.d.get("channel") or {}).get("id")
    if args.confirm:
        if args.channel_id and args.channel_id != ch["id"]:
            raise Fatal(f"--channel-id {args.channel_id} is not the channel of this token.")
        state.d["channel"] = {"id": ch["id"], "title": ch["snippet"]["title"],
                              "confirmed_at": rfc3339(now_utc())}
        state.save()
        out("Confirmed and stored in state.json. Uploads go to this channel only.")
    elif stored == ch["id"]:
        out("This is the confirmed channel.")
    else:
        out("Not confirmed yet. If this is the right channel, run:  "
            "tools/youtube_publish.py whoami --confirm")
    return 0


def dry_run_upload(paths, plan, state, selection, args, out):
    api = Api(None, None, dry_run=True, out=out)
    out("DRY RUN: no API call, no download, nothing written. Per video, in this order:")
    out("  WOULD SEND GET " + API_BASE + "/youtube/v3/channels?part=snippet,contentDetails,status&mine=true"
        "   [channels.list: 1 unit; must match the confirmed channel]")
    known = set(state.d["playlists"])
    listed = False
    now = now_utc()
    for vid in selection:
        it = next(i for i in plan["videos"] if i["id"] == vid)
        out(f"\n{vid}: {it['title']}")
        if state.is_done(vid):
            out("  already done; nothing would be sent")
            continue
        if it["violations"]:
            out(f"  SKIPPED: violations: {it['violations']}")
            continue
        if not state.uploaded(vid) and parse_rfc3339(it["publish_at"]) < now + dt.timedelta(minutes=args.lead_minutes):
            out(f"  SKIPPED: publish time {it['publish_at_local']} is in the past"
                + (" (--reschedule would move it)" if args.reschedule else ""))
            continue
        vstate = state.d["videos"].get(vid, {})
        if not vstate.get("video_id"):
            local = os.path.join(paths.out, f"{vid}.mp4")
            if os.path.exists(local):
                out(f"  WOULD USE the local file {paths.rel(local)} ({it['size_bytes']} bytes, SHA-256 checked)")
            else:
                out(f"  WOULD DOWNLOAD {it['asset_url']} ({it['size_bytes']} bytes, size and SHA-256 checked)")
            out("  WOULD LIST the channel's uploads and stop if this title exists already "
                "[playlistItems.list: 1 unit per 50 videos, once per run]")
            api.start_upload(insert_body(it, plan["settings"]), it["size_bytes"] or 0,
                             plan["settings"]["notify_subscribers"])
            out(f"  WOULD SEND PUT <session address from the Location header>  "
                f"<{it['size_bytes']} bytes of {vid}.mp4>")
        video_id = vstate.get("video_id") or "<NEW_VIDEO_ID>"
        steps = vstate.get("steps", {})
        if steps.get("thumbnail", {}).get("status") != "ok":
            api.set_thumbnail(video_id, os.path.join(paths.root, it["thumbnail"]))
        if steps.get("captions", {}).get("status") != "ok":
            api.insert_caption(video_id, os.path.join(paths.root, it["captions"]),
                               plan["settings"]["caption_language"], plan["settings"]["caption_name"])
        for key in it["playlists"]:
            if steps.get("playlists", {}).get("items", {}).get(key, {}).get("status") == "ok":
                continue
            d = next(p for p in plan["playlists"] if p["key"] == key)
            if key not in known:
                if not listed:
                    out("  WOULD LIST your playlists and reuse one with the same title if it exists "
                        "[playlists.list: 1 unit per 50, once per run]")
                    listed = True
                api.create_playlist(d["title"], d["description"], plan["settings"]["playlist_privacy"],
                                    plan["settings"]["language"])
                known.add(key)
            api.add_to_playlist(state.d["playlists"].get(key, {}).get("id", f"<ID of playlist {key}>"), video_id)
        api.call("videos.list", "GET", "/youtube/v3/videos",
                 {"part": "snippet,status,contentDetails,processingDetails", "id": video_id})
        units, uploads = video_cost(state, vid, it["playlists"])
        out(f"  cost for this video: about {units} units and {uploads} videos.insert call(s) "
            "(a playlist that must still be created is counted with 50 units, for every "
            "video of this dry run that needs it)")
    return 0


def cmd_upload(paths, args, out=print):
    plan = need_plan(paths)
    state = State(paths.state, read_only=args.dry_run)
    selection = select_videos(args, plan, state)
    if args.dry_run:
        return dry_run_upload(paths, plan, state, selection, args, out)
    channel = expected_channel(args, state)
    if plan.get("problems"):
        raise Fatal("the plan has problems; run plan and check first: " + plan["problems"][0])
    if args.chunk_mb and (args.chunk_mb * 4) % 1:
        raise Fatal("--chunk-mb must be a multiple of 0.25 (256 KB)")
    with run_lock(paths):
        api, ledger = make_api(paths, state, args, out)
        up = Uploader(paths, plan, state, api, ledger, out=out, lead_minutes=args.lead_minutes,
                      chunk=int(args.chunk_mb * 1024 * 1024) if args.chunk_mb else None,
                      verify_wait=args.verify_wait, adopt=args.adopt)
        started = rfc3339(now_utc())
        try:
            summary = up.run(selection, channel, reschedule=args.reschedule)
        finally:
            state.save()
        state.d["runs"] = (state.d["runs"] + [{"started": started, "finished": rfc3339(now_utc()),
                                               **{k: v for k, v in summary.items()}}])[-60:]
        state.save()
    t = ledger.today()
    out("")
    out(f"Run summary: {len(summary['done'])} finished, {len(summary['pending'])} waiting for "
        f"YouTube processing or a failed step, {len(summary['failed'])} failed, "
        f"{len(summary['skipped_past'])} skipped (time in the past), "
        f"{len(summary['skipped_violation'])} skipped (violations).")
    out(f"Quota used today (Pacific day {ledger.day()}): {t['units']} of {ledger.daily_units} units, "
        f"{t['uploads']} of {ledger.daily_uploads} videos.insert calls.")
    if summary["stopped"]:
        out("STOPPED: " + summary["stopped"])
    cmd_report(paths, args, out=lambda *_: None)
    left = [it["id"] for it in plan["videos"] if not state.is_done(it["id"])]
    out(f"Finished so far: {TOTAL_VIDEOS - len(left)} of {TOTAL_VIDEOS}. Report: {paths.rel(paths.report_md)}")
    return 1 if summary["failed"] else 0


def step_label(v, name):
    s = v.get("steps", {}).get(name, {}).get("status", "pending")
    return {"ok": "ok", "failed": "FAILED", "processing": "processing", "started": "started"}.get(s, "-")


def cmd_report(paths, args, out=print):
    plan = need_plan(paths)
    state = State(paths.state, read_only=True)
    zone = tz(OWNER_TZ)
    rows, counts = [], {"done": 0, "uploaded": 0, "failed_steps": 0, "not started": 0}
    for it in plan["videos"]:
        v = state.d["videos"].get(it["id"], {})
        steps = [step_label(v, n) for n in STEP_NAMES]
        if v.get("done"):
            overall = "done"
            counts["done"] += 1
        elif v.get("video_id"):
            overall = "uploaded, incomplete"
            counts["uploaded"] += 1
        else:
            overall = "not started" if "FAILED" not in steps else "upload failed"
            counts["not started"] += 1
        counts["failed_steps"] += steps.count("FAILED")
        last_err = (v.get("errors") or [{}])[-1].get("message", "") if "FAILED" in steps else ""
        rows.append([it["id"], it["title"], fmt_local(parse_rfc3339(it["publish_at"]), zone),
                     it["publish_at"], v.get("url") or "", overall] + steps + [last_err])
    header = ["video", "title", f"publish_time_{OWNER_TZ}", "publish_time_utc", "url", "state"] \
        + STEP_NAMES + ["last_error"]
    q = state.d.get("quota", {})
    L = ["# YouTube upload report", "",
         f"Written by `tools/youtube_publish.py report` on {rfc3339(now_utc())} from "
         "`state.json` and `plan.json` (no API call). `verify` compares with YouTube itself.", "",
         f"- Channel: {(state.d.get('channel') or {}).get('title', 'not confirmed yet')} "
         f"({(state.d.get('channel') or {}).get('id', '-')})",
         f"- Finished (all five steps ok): {counts['done']} of {len(rows)}",
         f"- Uploaded but with a step open: {counts['uploaded']}",
         f"- Not uploaded yet: {counts['not started']}",
         f"- Steps in FAILED state: {counts['failed_steps']}",
         f"- Playlists created or found: {len(state.d.get('playlists', {}))} of {len(plan['playlists'])}", ""]
    if q:
        L += ["## Quota used (per Pacific-time day, counted by the tool)", "",
              "| Day | Units | videos.insert calls |", "|---|---|---|"]
        L += [f"| {d} | {q[d]['units']} | {q[d]['uploads']} |" for d in sorted(q)[-30:]] + [""]
    L += ["## Videos", "", "| Video | Publish time (" + OWNER_TZ + ") | URL | State | "
          + " | ".join(STEP_NAMES) + " | Last error |", "|---|---|---|---|" + "---|" * (len(STEP_NAMES) + 1)]
    for r in rows:
        L.append(f"| {r[0]} | {r[2]} | {r[4] or '-'} | {r[5]} | " + " | ".join(r[6:6 + len(STEP_NAMES)])
                 + f" | {r[-1].replace('|', '/')[:120]} |")
    text = "\n".join(L) + "\n"
    buf = io.StringIO()
    w = csv.writer(buf)
    w.writerow(header)
    w.writerows(rows)
    out(f"Finished {counts['done']} of {len(rows)}; uploaded with a step open {counts['uploaded']}; "
        f"not uploaded {counts['not started']}; failed steps {counts['failed_steps']}.")
    if getattr(args, "dry_run", False):
        out("DRY RUN: REPORT.md and report.csv were not written.")
    else:
        atomic_write(paths.report_md, text)
        atomic_write(paths.report_csv, buf.getvalue())
        out(f"Wrote {paths.rel(paths.report_md)} and {paths.rel(paths.report_csv)}")
    return 0


def compare_video(item, res, settings, memberships, now):
    """Differences between the plan and one videos.list resource."""
    d, sn, stt, cd = [], res.get("snippet", {}), res.get("status", {}), res.get("contentDetails", {})
    if sn.get("title") != item["title"]:
        d.append(f"title: YouTube has {sn.get('title')!r}")
    if (sn.get("description") or "").strip() != item["description"].strip():
        d.append("description differs")
    if sorted(sn.get("tags") or []) != sorted(item["tags"]):
        d.append(f"tags: YouTube has {sn.get('tags')}")
    if str(sn.get("categoryId")) != str(settings["category_id"]):
        d.append(f"categoryId: YouTube has {sn.get('categoryId')}")
    if sn.get("defaultLanguage") != settings["language"]:
        d.append(f"defaultLanguage: YouTube has {sn.get('defaultLanguage')}")
    if sn.get("defaultAudioLanguage") != settings["audio_language"]:
        d.append(f"defaultAudioLanguage: YouTube has {sn.get('defaultAudioLanguage')}")
    slot = parse_rfc3339(item["publish_at"])
    priv, pa = stt.get("privacyStatus"), stt.get("publishAt")
    if now < slot:
        if priv != "private":
            d.append(f"privacy: {priv} before the publish time")
        if not pa or parse_rfc3339(pa) != slot:
            d.append(f"publish time: YouTube has {pa}, the plan has {item['publish_at']}")
    elif priv != "public":
        d.append(f"privacy: still {priv} after the publish time {item['publish_at_local']}"
                 " (see README, 'A video stays private')")
    if stt.get("uploadStatus") in ("failed", "rejected", "deleted"):
        d.append(f"uploadStatus: {stt.get('uploadStatus')}")
    if "selfDeclaredMadeForKids" in stt and stt["selfDeclaredMadeForKids"] != bool(settings["made_for_kids"]):
        d.append("made-for-kids setting differs")
    if cd.get("hasCustomThumbnail") is False:
        d.append("thumbnail: no custom thumbnail")
    if cd.get("caption") != "true":
        d.append("captions: YouTube reports none")
    for key in item["playlists"]:
        if res["id"] not in memberships.get(key, set()):
            d.append(f"playlist: not in {key}")
    return d


def cmd_verify(paths, args, out=print):
    plan = need_plan(paths)
    state = State(paths.state, read_only=args.dry_run)
    uploaded = [it for it in plan["videos"] if state.uploaded(it["id"])]
    if args.dry_run:
        api = Api(None, None, dry_run=True, out=out)
        out(f"DRY RUN: {len(uploaded)} uploaded videos would be read back.")
        ids = [state.d["videos"][it["id"]]["video_id"] for it in uploaded] or ["<VIDEO_IDS>"]
        api.videos(ids)
        for key, p in state.d["playlists"].items():
            api.call("playlistItems.list", "GET", "/youtube/v3/playlistItems",
                     {"part": "snippet", "playlistId": p["id"], "maxResults": "50"})
        return 0
    channel = expected_channel(args, state)
    api, ledger = make_api(paths, state, args, out)
    ch = api.my_channel()
    if ch["id"] != channel:
        raise Fatal(f"the token belongs to {ch['id']}, not to the confirmed channel {channel}.")
    by_id = {state.d["videos"][it["id"]]["video_id"]: it for it in uploaded}
    try:
        resources = {r["id"]: r for r in api.videos(list(by_id), "snippet,status,contentDetails")}
        memberships = {}
        for key, p in state.d["playlists"].items():
            items = api.list_all("playlistItems.list", "/youtube/v3/playlistItems",
                                 {"part": "snippet", "playlistId": p["id"]})
            memberships[key] = {i["snippet"]["resourceId"]["videoId"] for i in items}
            ids = [i["snippet"]["resourceId"]["videoId"] for i in items]
            dup = sorted({v for v in ids if ids.count(v) > 1})
            if dup:
                out(f"DIFFERENCE playlist {key}: videos listed twice: {dup}")
    except StopRun as e:
        out("STOPPED: " + str(e))
        return 2
    now, total, lines = now_utc(), 0, []
    for video_id, it in by_id.items():
        res = resources.get(video_id)
        diffs = ["YouTube does not return this video (deleted, or another channel)"] if res is None \
            else compare_video(it, res, plan["settings"], memberships, now)
        for d in diffs:
            lines.append(f"{it['id']} ({video_id}): {d}")
        total += len(diffs)
        state.video(it["id"])["last_verify"] = {"at": rfc3339(now), "differences": diffs}
    state.save()
    for line in lines:
        out("DIFFERENCE " + line)
    out(f"verify: {len(uploaded)} uploaded videos compared, {total} differences; "
        f"{TOTAL_VIDEOS - len(uploaded)} not uploaded yet.")
    atomic_write(paths.verify_md, "# Verification against YouTube\n\n"
                 f"Read from the API on {rfc3339(now)}. {len(uploaded)} uploaded videos compared, "
                 f"{total} differences.\n\n" + "".join(f"- {x}\n" for x in lines))
    return 1 if total else 0


def cmd_retime(paths, args, out=print):
    """Apply the plan's publish time to uploaded videos that still have another one."""
    plan = need_plan(paths)
    state = State(paths.state, read_only=args.dry_run)
    todo = [it for it in plan["videos"] if state.uploaded(it["id"])
            and parse_rfc3339(state.d["videos"][it["id"]].get("publish_at") or it["publish_at"])
            != parse_rfc3339(it["publish_at"])]
    if getattr(args, "only", None):
        todo = [it for it in todo if it["id"] in [v.upper() for v in args.only]]
    out(f"{len(todo)} uploaded videos have a publish time that differs from the plan.")
    if not todo:
        return 0
    if args.dry_run:
        api = Api(None, None, dry_run=True, out=out)
        for it in todo:
            out(f"{it['id']}: {state.d['videos'][it['id']]['publish_at']} -> {it['publish_at']}")
            api.update_status(state.d["videos"][it["id"]]["video_id"],
                              {"privacyStatus": "private", "publishAt": it["publish_at"],
                               "...": "the other status fields are copied from YouTube unchanged"})
        return 0
    channel = expected_channel(args, state)
    with run_lock(paths):
        api, ledger = make_api(paths, state, args, out)
        if api.my_channel()["id"] != channel:
            raise Fatal("the token does not belong to the confirmed channel.")
        now, n = now_utc(), 0
        try:
            for it in todo:
                vid, video_id = it["id"], state.d["videos"][it["id"]]["video_id"]
                if parse_rfc3339(it["publish_at"]) < now + dt.timedelta(minutes=args.lead_minutes):
                    out(f"{vid}: SKIPPED, the new time is in the past")
                    continue
                if not ledger.can(QUOTA_COST["videos.update"] + 1):
                    raise StopRun("not enough quota left today. " + ledger.rerun_hint())
                res = api.videos([video_id], "status")
                cur = res[0]["status"] if res else {}
                if cur.get("privacyStatus") != "private":
                    out(f"{vid}: SKIPPED, it is {cur.get('privacyStatus', 'missing')}; only a private, "
                        "never published video can be rescheduled")
                    continue
                body = {k: cur[k] for k in ("embeddable", "license", "publicStatsViewable",
                                            "selfDeclaredMadeForKids", "containsSyntheticMedia") if k in cur}
                body.update(privacyStatus="private", publishAt=it["publish_at"])
                api.update_status(video_id, body)
                state.video(vid)["publish_at"] = it["publish_at"]
                state.save()
                n += 1
                out(f"{vid}: now scheduled for {it['publish_at_local']}")
        except StopRun as e:
            out("STOPPED: " + str(e))
    out(f"retime: {n} videos changed.")
    return 0


# --------------------------------------------------------------------------
# Self-test (offline; a local http.server stands in for the API)
# --------------------------------------------------------------------------

class FakeYouTube:
    """A small stand-in for the parts of the API this tool calls."""

    def __init__(self):
        self.calls = {}
        self.videos = {}
        self.sessions = {}
        self.playlists = {}
        self.playlist_items = []
        self.captions = {}
        self.thumbs = {}
        self.fail_once = {}       # name -> HTTP status to answer once
        self.drop_after = None    # close the connection after this many body bytes, once
        self.channel_id = "UCfakechannel0000000000A"
        self.token_refreshes = 0
        self.lock = threading.Lock()
        fake = self

        class H(http.server.BaseHTTPRequestHandler):
            def log_message(self, *a):
                pass

            def _send(self, status, obj=None, headers=None):
                data = b"" if obj is None else json.dumps(obj).encode()
                self.send_response(status)
                for k, v in (headers or {}).items():
                    self.send_header(k, v)
                self.send_header("Content-Length", str(len(data)))
                self.end_headers()
                self.wfile.write(data)

            def _err(self, status, reason):
                self._send(status, {"error": {"code": status, "message": reason,
                                              "errors": [{"reason": reason}]}})

            def _gate(self, name):
                with fake.lock:
                    fake.calls[name] = fake.calls.get(name, 0) + 1
                    st = fake.fail_once.pop(name, None)
                if st:
                    self._err(st, "backendError" if st >= 500 else "forbidden")
                    return False
                if name != "token" and self.headers.get("Authorization") != "Bearer fake-access":
                    self._err(401, "authError")
                    return False
                return True

            def _body(self):
                return self.rfile.read(int(self.headers.get("Content-Length", "0")))

            def do_GET(self):
                u = urllib.parse.urlsplit(self.path)
                q = {k: v[0] for k, v in urllib.parse.parse_qs(u.query).items()}
                name = {"/youtube/v3/channels": "channels.list", "/youtube/v3/videos": "videos.list",
                        "/youtube/v3/playlists": "playlists.list",
                        "/youtube/v3/playlistItems": "playlistItems.list"}.get(u.path)
                if not name:
                    return self._err(404, "notFound")
                if not self._gate(name):
                    return
                if name == "channels.list":
                    return self._send(200, {"items": [{
                        "id": fake.channel_id, "snippet": {"title": "Fake Channel"},
                        "status": {"longUploadsStatus": "allowed"},
                        "contentDetails": {"relatedPlaylists": {"uploads": "UUfake"}}}]})
                if name == "videos.list":
                    return self._send(200, {"items": [fake.videos[i] for i in q["id"].split(",")
                                                      if i in fake.videos]})
                if name == "playlists.list":
                    return self._send(200, {"items": [{"id": k, "snippet": {"title": v["title"]}}
                                                      for k, v in fake.playlists.items()]})
                pid = q["playlistId"]
                if pid == "UUfake":
                    items = [{"id": "u" + v["id"], "snippet": {"title": v["snippet"]["title"],
                              "resourceId": {"videoId": v["id"]}}} for v in fake.videos.values()]
                else:
                    items = [{"id": i["id"], "snippet": {"resourceId": {"videoId": i["video"]}}}
                             for i in fake.playlist_items if i["playlist"] == pid
                             and q.get("videoId") in (None, i["video"])]
                return self._send(200, {"items": items})

            def do_POST(self):
                u = urllib.parse.urlsplit(self.path)
                q = {k: v[0] for k, v in urllib.parse.parse_qs(u.query).items()}
                if u.path == "/token":
                    self._gate("token")
                    form = urllib.parse.parse_qs(self._body().decode())
                    fake.token_refreshes += 1
                    if form.get("refresh_token") != ["fake-refresh"]:
                        return self._send(400, {"error": "invalid_grant"})
                    return self._send(200, {"access_token": "fake-access", "expires_in": 3600})
                name = {"/upload/youtube/v3/videos": "videos.insert",
                        "/upload/youtube/v3/thumbnails/set": "thumbnails.set",
                        "/upload/youtube/v3/captions": "captions.insert",
                        "/youtube/v3/playlists": "playlists.insert",
                        "/youtube/v3/playlistItems": "playlistItems.insert"}.get(u.path)
                body = self._body()
                if not name:
                    return self._err(404, "notFound")
                if not self._gate(name):
                    return
                if name == "videos.insert":
                    meta = json.loads(body.decode())
                    sid = f"s{len(fake.sessions) + 1}"
                    fake.sessions[sid] = {"meta": meta, "data": b"", "video": None,
                                          "total": int(self.headers["X-Upload-Content-Length"])}
                    host = self.headers["Host"]
                    return self._send(200, None, {"Location":
                                      f"http://{host}/upload/youtube/v3/videos?uploadType=resumable&upload_id={sid}"})
                if name == "thumbnails.set":
                    fake.thumbs[q["videoId"]] = len(body)
                    fake.videos[q["videoId"]]["contentDetails"]["hasCustomThumbnail"] = True
                    return self._send(200, {"items": [{}]})
                if name == "captions.insert":
                    meta = json.loads(re.search(rb"\r\n\r\n(\{.*?\})\r\n--", body, re.S).group(1))
                    vidid = meta["snippet"]["videoId"]
                    key = (vidid, meta["snippet"]["language"], meta["snippet"]["name"])
                    if key in fake.captions:
                        return self._err(409, "captionExists")
                    fake.captions[key] = len(body)
                    fake.videos[vidid]["contentDetails"]["caption"] = "true"
                    return self._send(200, {"id": "cap" + vidid})
                data = json.loads(body.decode())
                if name == "playlists.insert":
                    pid = f"PL{len(fake.playlists) + 1:03d}"
                    fake.playlists[pid] = {"title": data["snippet"]["title"],
                                           "privacy": data["status"]["privacyStatus"]}
                    return self._send(200, {"id": pid})
                iid = f"PI{len(fake.playlist_items) + 1:04d}"
                fake.playlist_items.append({"id": iid, "playlist": data["snippet"]["playlistId"],
                                            "video": data["snippet"]["resourceId"]["videoId"]})
                return self._send(200, {"id": iid})

            def do_PUT(self):
                u = urllib.parse.urlsplit(self.path)
                q = {k: v[0] for k, v in urllib.parse.parse_qs(u.query).items()}
                if u.path == "/youtube/v3/videos":
                    body = json.loads(self._body().decode())
                    if not self._gate("videos.update"):
                        return
                    fake.videos[body["id"]]["status"].update(body["status"])
                    return self._send(200, fake.videos[body["id"]])
                s = fake.sessions.get(q.get("upload_id"))
                if s is None:
                    self._body()
                    return self._err(404, "notFound")
                with fake.lock:
                    fake.calls["upload.put"] = fake.calls.get("upload.put", 0) + 1
                length = int(self.headers.get("Content-Length", "0"))
                cr = self.headers.get("Content-Range", "")
                if cr.startswith("bytes */"):
                    with fake.lock:
                        fake.calls["upload.status"] = fake.calls.get("upload.status", 0) + 1
                    if s["video"]:
                        return self._send(201, s["video"])
                    hdr = {"Range": f"bytes=0-{len(s['data']) - 1}"} if s["data"] else {}
                    return self._send(308, None, hdr)
                start = int(re.match(r"bytes (\d+)-", cr).group(1)) if cr else 0
                if start != len(s["data"]):
                    self.rfile.read(length)
                    return self._err(400, "invalidRange")
                if fake.drop_after is not None:
                    keep, fake.drop_after = min(fake.drop_after, length), None
                    s["data"] += self.rfile.read(keep)
                    self.close_connection = True
                    with contextlib.suppress(OSError):
                        self.connection.shutdown(2)
                    return
                s["data"] += self.rfile.read(length)
                if len(s["data"]) < s["total"]:
                    return self._send(308, None, {"Range": f"bytes=0-{len(s['data']) - 1}"})
                vid_id = f"vid{len(fake.videos) + 1:03d}"
                meta = s["meta"]
                video = {"id": vid_id, "snippet": meta["snippet"],
                         "status": dict(meta["status"], uploadStatus="processed"),
                         "contentDetails": {"duration": fake.duration_for(meta), "caption": "false",
                                            "hasCustomThumbnail": False},
                         "processingDetails": {"processingStatus": "succeeded"},
                         "_sha256": hashlib.sha256(s["data"]).hexdigest()}
                fake.videos[vid_id] = s["video"] = video
                return self._send(201, video)

        self.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), H)
        self.server.handle_error = lambda *a: None   # a client that "crashes" is expected here
        self.base = f"http://127.0.0.1:{self.server.server_address[1]}"
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def duration_for(self, meta):
        return "PT1M40S"

    def inserts(self):
        return self.calls.get("videos.insert", 0)

    def close(self):
        self.server.shutdown()
        self.server.server_close()


class SimulatedCrash(BaseException):
    """Stands in for a power cut or a killed process during the self-test."""


def selftest(paths):
    results = []

    def test(name):
        def deco(fn):
            try:
                fn()
                results.append((name, None))
                print(f"ok    {name}")
            except Exception as e:   # noqa: BLE001
                import traceback
                results.append((name, e))
                print(f"FAIL  {name}: {e!r}")
                traceback.print_exc()
            return fn
        return deco

    ist = tz(OWNER_TZ)
    cfg = json.loads(json.dumps(DEFAULT_CONFIG))

    @test("metadata: all 201 entries parse, with title, description and thumbnail")
    def _():
        with open(paths.metadata, encoding="utf-8") as f:
            meta, order = parse_metadata(f.read())
        assert order == [vid_name(i) for i in range(1, 202)], "order"
        for vid, m in meta.items():
            assert m.get("title") and m.get("description"), vid
            assert m.get("thumbnail") == f"thumbnails/{vid}.png", vid
            assert not validate_title(m["title"]), (vid, validate_title(m["title"]))
        td = {x["id"]: x for x in read_json(paths.thumb_data)}
        assert all(td[v]["youtube_title"] == meta[v]["title"] and
                   td[v]["description"] == meta[v]["description"] for v in meta), "json and md agree"
        assert len({m["title"] for m in meta.values()}) == 201, "titles unique"

    @test("curriculum: 12 parts cover V001 to V201 and agree with the master table")
    def _():
        with open(paths.curriculum, encoding="utf-8") as f:
            parts, vp = parse_curriculum(f.read())
        assert sorted(parts) == list(range(12)) and len(vp) == 201
        assert sum(p["count"] for p in parts.values()) == 201
        for vid, p in vp.items():
            assert parts[p]["first"] <= vid_num(vid) <= parts[p]["last"], vid
        assert parts[0]["name"] == "Orientation" and parts[11]["last"] == 201

    @test("QC record: 201 rows parse, lengths are read as seconds")
    def _():
        with open(paths.qc, encoding="utf-8") as f:
            qc = parse_qc(f.read())
        assert len(qc) == 201 and qc["V001"]["seconds"] == 18 * 60 + 49
        assert parse_clock("1:02:03") == 3723

    @test("release assets: batch tags and URLs")
    def _():
        assert release_tag(33) == "videos-batch-01" and release_tag(34) == "videos-batch-02"
        assert release_tag(99) == "videos-batch-03" and release_tag(100) == "videos-batch-04"
        assert release_tag(166) == "videos-batch-05" and release_tag(201) == "videos-batch-06"
        assert asset_url("V134") == ("https://github.com/harshaksh-singh/git-github-mastery/"
                                     "releases/download/videos-batch-05/V134.mp4")
        assert host_allowed("https://release-assets.githubusercontent.com/x")
        assert not host_allowed("https://evilgithub.com/x") and not host_allowed("https://github.com.evil.io/x")

    @test("schedule: across midnight and month ends in Asia/Kolkata, RFC 3339 output")
    def _():
        s = parse_local_start("2026-10-31 14:00", ist)
        t = [slot_time(s, 5, i) for i in range(4)]
        assert [fmt_local(x, ist) for x in t] == ["2026-10-31 14:00", "2026-10-31 19:00",
                                                  "2026-11-01 00:00", "2026-11-01 05:00"]
        assert rfc3339(t[0]) == "2026-10-31T08:30:00Z"
        assert rfc3339(t[2], ist) == "2026-11-01T00:00:00+05:30"
        assert rfc3339(t[2]) == "2026-10-31T18:30:00Z"      # previous day and month in UTC
        assert parse_rfc3339(rfc3339(t[2], ist)) == parse_rfc3339(rfc3339(t[2]))
        s = parse_local_start("2026-12-31 22:30", ist)        # year end
        assert rfc3339(slot_time(s, 5, 1), ist) == "2027-01-01T03:30:00+05:30"
        s = parse_local_start("2028-02-28 23:00", ist)        # leap day
        assert rfc3339(slot_time(s, 5, 1), ist) == "2028-02-29T04:00:00+05:30"
        assert rfc3339(slot_time(s, 5, 6), ist) == "2028-03-01T05:00:00+05:30"
        last = slot_time(parse_local_start("2026-10-20 09:00", ist), 5, 200)
        assert rfc3339(last, ist) == "2026-12-01T01:00:00+05:30"   # 200 gaps = 41 days 16 hours
        assert rfc3339(slot_time(s, 0.5, 1), ist) == "2028-02-28T23:30:00+05:30"
        assert parse_rfc3339("2026-10-31T08:30:00.0Z") == t[0]
        try:
            parse_local_start("20-10-2026 9am", ist)
            raise AssertionError("bad start accepted")
        except Fatal:
            pass

    @test("description: assembly, 5000-byte limit counted in bytes, < and > rejected")
    def _():
        ch = parse_chapters("0:00 Hook\n0:59 Introduction\n1:57 Recap\n")
        d = assemble_description("Body text. ", ch, "Course: https://example.org")
        assert d == "Body text.\n\n0:00 Hook\n0:59 Introduction\n1:57 Recap\n\nCourse: https://example.org"
        assert not validate_description(d)
        assert validate_description("a" * 5000) == [] and validate_description("a" * 5001)
        assert validate_description("é" * 2501), "counted in bytes, not characters"
        assert not validate_description("é" * 2500)
        assert validate_description("x <b> y") and validate_title("a > b")
        assert validate_title("t" * 100) == [] and validate_title("t" * 101) and validate_title("")

    @test("tags: the 500-character budget as YouTube counts it")
    def _():
        assert tags_length(["Foo-Baz"]) == 7 and tags_length(["Foo Baz"]) == 9
        assert tags_length(["a", "b c"]) == 1 + 1 + 5
        assert validate_tags(["a" * 500]) == [] and validate_tags(["a" * 501])
        assert validate_tags(["a" * 249, "b" * 250]) == [] and validate_tags(["a" * 250, "b" * 250])
        assert validate_tags(["git", "Git"]) and validate_tags(["a,b"]) and validate_tags(["a<b"])
        assert command_tag("git cat-file -p") == "git cat-file" and command_tag("labs/shell m00") is None
        assert command_tag("GIT_TRACE=1 git") is None and command_tag("git --version") is None
        t = build_tags(cfg, "V001", 2, "git merge --no-ff")
        assert t[0] == "git" and "git merge" in t and len(t) == len({x.lower() for x in t})

    @test("chapters: first at 0:00, at least three, ascending, each at least 10 seconds")
    def _():
        good = parse_chapters("0:00 A\n0:30 B\n1:00 C\n")
        assert validate_chapters(good, 90) == []
        assert validate_chapters(parse_chapters("0:05 A\n0:30 B\n1:00 C\n"), 90)
        assert validate_chapters(parse_chapters("0:00 A\n0:30 B\n"), 90)
        assert validate_chapters(parse_chapters("0:00 A\n0:09 B\n1:00 C\n"), 90)
        assert validate_chapters(parse_chapters("0:00 A\n1:00 B\n0:30 C\n"), 90)
        assert validate_chapters(good, 65), "last chapter shorter than 10 s"
        assert validate_chapters(parse_chapters("0:00 A <x>\n0:30 B\n1:00 C\n"), 90)
        assert parse_chapters("1:02:03 Long\n")[0][0] == 3723
        for bad in ("Hook 0:00", "0:0 Hook", "0:00"):
            try:
                parse_chapters(bad)
                raise AssertionError(bad)
            except ValueError:
                pass

    @test("captions: SRT parser accepts a good file and reports bad ones")
    def _():
        cues, errs = parse_srt("1\n00:00:01,000 --> 00:00:02,000\nHello\n\n2\n00:00:02,500 --> 00:00:04,000\nA\nB\n")
        assert len(cues) == 2 and not errs and cues[1][1] == 4000
        assert parse_srt("1\n00:00:02,000 --> 00:00:01,000\nx\n")[1]
        assert parse_srt("1\n0:00:02 -> 0:00:03\nx\n")[1] and parse_srt("")[1]

    @test("OAuth: authorization URL, PKCE pair, loopback redirect, scopes")
    def _():
        v, c = pkce_pair()
        assert 43 <= len(v) <= 128 and re.fullmatch(r"[A-Za-z0-9._~-]+", v)
        assert c == base64.urlsafe_b64encode(hashlib.sha256(v.encode()).digest()).rstrip(b"=").decode()
        assert "=" not in c and len(c) == 43
        url = build_auth_url("abc.apps.googleusercontent.com", "http://127.0.0.1:53124", "st8", c)
        u = urllib.parse.urlsplit(url)
        q = urllib.parse.parse_qs(u.query)
        assert (u.scheme, u.netloc, u.path) == ("https", "accounts.google.com", "/o/oauth2/v2/auth")
        assert q["client_id"] == ["abc.apps.googleusercontent.com"] and q["response_type"] == ["code"]
        assert q["redirect_uri"] == ["http://127.0.0.1:53124"] and q["state"] == ["st8"]
        assert q["code_challenge"] == [c] and q["code_challenge_method"] == ["S256"]
        assert q["scope"] == ["https://www.googleapis.com/auth/youtube.upload "
                              "https://www.googleapis.com/auth/youtube.force-ssl"]
        assert "client_secret" not in url and "+" not in u.query

    tmp_root = tempfile.mkdtemp(prefix="ytpub-selftest-")

    def sandbox(name, n_videos=3, size=700_000):
        """A miniature course: n videos with real-looking files, and a fake API."""
        root = os.path.join(tmp_root, name)
        p = Paths(root, os.path.join(root, "_config"), os.path.join(root, "_cache"))
        os.makedirs(p.out)
        os.makedirs(p.thumbs)
        os.makedirs(p.yt)
        os.makedirs(os.path.join(root, "_assets"))
        items = []
        for i in range(1, n_videos + 1):
            vid = vid_name(i)
            data = hashlib.sha256(vid.encode()).digest() * (size // 32) + bytes([i]) * i
            with open(os.path.join(root, "_assets", vid + ".mp4"), "wb") as f:
                f.write(data)
            with open(os.path.join(p.thumbs, vid + ".png"), "wb") as f:
                f.write(b"\x89PNG\r\n\x1a\n" + b"\0\0\0\rIHDR" + struct.pack(">II", 1280, 720) + b"x" * 64)
            with open(os.path.join(p.out, vid + ".srt"), "w") as f:
                f.write("1\n00:00:01,000 --> 00:00:02,000\nHello\n")
            t = slot_time(dt.datetime(2030, 1, 1, 9, 0, tzinfo=ist), 5, i - 1)
            items.append({"id": vid, "number": i, "part": 0, "part_name": "Orientation",
                          "title": f"Test video {i}", "publish_at": rfc3339(t),
                          "publish_at_local": rfc3339(t, ist), "playlists": ["course", "part-00"],
                          "description": f"Body {i}\n\n0:00 A\n0:30 B\n1:00 C\n\nlink", "tags": ["git", "t a"],
                          "thumbnail": p.rel(os.path.join(p.thumbs, vid + ".png")),
                          "captions": p.rel(os.path.join(p.out, vid + ".srt")),
                          "asset_url": asset_url(vid), "size_bytes": len(data),
                          "sha256": hashlib.sha256(data).hexdigest(), "duration_seconds": 100.0,
                          "violations": []})
        plan = {"version": 1, "timezone": OWNER_TZ, "gap_hours": 5, "problems": [],
                "settings": {k: cfg[k] for k in (
                    "category_id", "language", "audio_language", "caption_language", "caption_name",
                    "made_for_kids", "contains_synthetic_media", "notify_subscribers", "license",
                    "embeddable", "public_stats_viewable", "playlist_privacy")},
                "playlists": [{"key": "course", "title": "Course", "description": "d"},
                              {"key": "part-00", "title": "Part 0", "description": "d"}],
                "videos": items}
        write_json(p.plan, plan)
        os.makedirs(p.config_dir)
        write_json(p.client_secret, {"installed": {"client_id": "cid", "client_secret": "csec"}})
        write_json(p.token, {"refresh_token": "fake-refresh", "access_token": "stale", "expires_at": 0}, 0o600)
        return p, plan

    def session(p, plan, fake, clock=None, **kw):
        """What one process start builds: fresh objects, everything read from disk."""
        clock = clock or (lambda: dt.datetime(2029, 12, 1, tzinfo=dt.timezone.utc))
        state = State(p.state)
        ledger = Ledger(state, kw.pop("daily_units", 10000), kw.pop("daily_uploads", 100), 100, clock)
        log = []
        api = Api(Tokens(p, token_uri=fake.base + "/token"), ledger, base=fake.base, out=log.append,
                  sleep=lambda s: None, backoff_base=0.0)

        def fetch(item):
            dest = os.path.join(p.cache_dir, item["id"] + ".mp4")
            os.makedirs(p.cache_dir, exist_ok=True)
            shutil.copyfile(os.path.join(p.root, "_assets", item["id"] + ".mp4"), dest)
            return dest, True
        up = Uploader(p, read_json(p.plan), state, api, ledger, out=log.append, clock=clock, fetch=fetch,
                      sleep=lambda s: None, **kw)
        return state, ledger, api, up, log

    @test("quota: costs are counted per Pacific day and the run stops before the limit")
    def _():
        p, plan = sandbox("quota")
        clock = [dt.datetime(2026, 10, 20, 6, 59, tzinfo=dt.timezone.utc)]   # 19 Oct 23:59 PDT
        st = State(p.state)
        led = Ledger(st, 1000, 2, 100, lambda: clock[0])
        assert led.day() == "2026-10-19" and led.units_left() == 900
        led.charge("captions.insert")
        led.charge("thumbnails.set")
        led.charge("videos.insert")
        assert led.today() == {"units": 450, "uploads": 1,
                               "calls": {"captions.insert": 1, "thumbnails.set": 1, "videos.insert": 1}}
        assert led.can(450, 1) and not led.can(451, 0) and not led.can(0, 2)
        led.charge("videos.insert")
        for name in ("videos.insert",):
            try:
                led.require(name)
                raise AssertionError("upload bucket not enforced")
            except StopRun as e:
                assert "midnight Pacific" in str(e)
        led.charge("captions.insert")
        led.require("thumbnails.set")                       # exactly 50 left: allowed
        led.charge("thumbnails.set")
        try:
            led.require("videos.list")
            raise AssertionError("unit limit not enforced")
        except StopRun:
            pass
        assert rfc3339(led.next_reset()) == "2026-10-20T07:00:00Z"
        clock[0] += dt.timedelta(minutes=2)                 # past midnight Pacific
        assert led.day() == "2026-10-20" and led.units_left() == 900 and led.uploads_left() == 2
        # cost of one complete video: thumbnail 50 + captions 400 + 2 playlist adds 100 + list 1
        st2 = State(os.path.join(p.yt, "none.json"))
        assert video_cost(st2, "V001", ["course", "part-00"]) == (651, 1)   # incl. creating 2 playlists
        st2.d["playlists"] = {"course": {"id": "a"}, "part-00": {"id": "b"}}
        assert video_cost(st2, "V001", ["course", "part-00"]) == (551, 1)
        st2.video("V001")["video_id"] = "x"
        st2.step("V001", "captions")["status"] = "ok"
        assert video_cost(st2, "V001", ["course", "part-00"]) == (151, 0)

    @test("fake server: full pipeline for 3 videos, then a rerun sends nothing new")
    def _():
        p, plan = sandbox("pipeline")
        fake = FakeYouTube()
        try:
            state, ledger, api, up, log = session(p, plan, fake)
            s = up.run(["V001", "V002", "V003"], fake.channel_id)
            assert s["done"] == ["V001", "V002", "V003"] and not s["failed"], (s, log)
            assert fake.inserts() == 3 and len(fake.videos) == 3
            assert len(fake.playlists) == 2 and len(fake.playlist_items) == 6
            assert len(fake.captions) == 3 and len(fake.thumbs) == 3
            for it in plan["videos"]:
                v = fake.videos[state.d["videos"][it["id"]]["video_id"]]
                assert v["_sha256"] == it["sha256"], "bytes arrived intact"
                assert v["status"]["privacyStatus"] == "private"
                assert v["status"]["publishAt"] == it["publish_at"]
                assert v["status"]["selfDeclaredMadeForKids"] is False
                assert v["snippet"]["title"] == it["title"] and v["snippet"]["categoryId"] == "27"
            assert fake.playlists["PL001"]["privacy"] == "public"
            t = ledger.today()
            # 3 x (50 + 400 + 100 + 1) + 2 playlists x 50 + channel 1 + uploads list 1 + playlists list 1
            assert t["units"] == 3 * 551 + 100 + 3 and t["uploads"] == 3, t
            assert not os.listdir(p.cache_dir), "temporary MP4s deleted"
            assert not read_json(p.sessions), "no session left"
            assert fake.token_refreshes == 1
            before = dict(fake.calls)
            state, ledger, api, up, log = session(p, plan, fake)
            s = up.run(["V001", "V002", "V003"], fake.channel_id)
            assert fake.inserts() == 3 and s["done"] == []
            assert {k: fake.calls[k] - before.get(k, 0) for k in fake.calls
                    if fake.calls[k] != before.get(k, 0)} == {"channels.list": 1}
            text = json.dumps(state.d) + "".join(map(str, log))
            assert "fake-access" not in text and "fake-refresh" not in text, "no token in state or output"
            assert oct(os.stat(p.token).st_mode & 0o777) == "0o600"
            assert oct(os.stat(p.sessions).st_mode & 0o777) == "0o600"
        finally:
            fake.close()

    @test("fake server: connection drops mid-upload, the same run resumes from the server's offset")
    def _():
        p, plan = sandbox("drop", 1, size=3_000_000)
        fake = FakeYouTube()
        try:
            fake.drop_after = 1_000_000
            state, ledger, api, up, log = session(p, plan, fake)
            s = up.run(["V001"], fake.channel_id)
            assert s["done"] == ["V001"], (s, log)
            assert fake.inserts() == 1 and fake.calls["upload.status"] >= 1
            assert any("resuming at byte 1000000" in str(x) for x in log), log
            assert list(fake.videos.values())[0]["_sha256"] == plan["videos"][0]["sha256"]
        finally:
            fake.close()

    @test("fake server: process killed mid-upload, the next run resumes the same session (one insert)")
    def _():
        p, plan = sandbox("crash", 2, size=3_000_000)
        fake = FakeYouTube()
        try:
            state, ledger, api, up, log = session(p, plan, fake, chunk=1024 * 1024)

            def hook(sent):
                if sent > 2_200_000:
                    raise SimulatedCrash()
            api.block_hook = hook
            try:
                up.run(["V001", "V002"], fake.channel_id)
                raise AssertionError("the simulated crash did not happen")
            except SimulatedCrash:
                pass
            assert fake.inserts() == 1 and not fake.videos
            assert read_json(p.state)["videos"]["V001"]["video_id"] is None
            assert read_json(p.state)["videos"]["V001"]["steps"]["insert"]["status"] == "started"
            assert "V001" in read_json(p.sessions)
            got = len(fake.sessions["s1"]["data"])
            assert got == 2 * 1024 * 1024, got
            state, ledger, api, up, log = session(p, plan, fake)       # "restart"
            s = up.run(["V001", "V002"], fake.channel_id)
            assert s["done"] == ["V001", "V002"], (s, log)
            assert fake.inserts() == 2 and len(fake.videos) == 2, "V001 was not inserted twice"
            assert any("continuing the earlier upload session at byte 2097152" in str(x) for x in log), log
            assert fake.videos["vid001"]["_sha256"] == plan["videos"][0]["sha256"]
        finally:
            fake.close()

    @test("resume: killed after the upload but before the record; the finished session is reused")
    def _():
        p, plan = sandbox("after", 1)
        fake = FakeYouTube()
        try:
            state, ledger, api, up, log = session(p, plan, fake)
            orig = api.send_file

            def crash_after(*a, **k):
                orig(*a, **k)
                raise SimulatedCrash()
            api.send_file = crash_after
            try:
                up.run(["V001"], fake.channel_id)
                raise AssertionError
            except SimulatedCrash:
                pass
            assert len(fake.videos) == 1 and read_json(p.state)["videos"]["V001"]["video_id"] is None
            state, ledger, api, up, log = session(p, plan, fake)
            s = up.run(["V001"], fake.channel_id)
            assert s["done"] == ["V001"] and fake.inserts() == 1 and len(fake.videos) == 1, (s, log)
        finally:
            fake.close()

    @test("resume: state lost entirely; the title guard refuses a second upload, --adopt records it")
    def _():
        p, plan = sandbox("guard", 1)
        fake = FakeYouTube()
        try:
            state, ledger, api, up, log = session(p, plan, fake)
            assert up.run(["V001"], fake.channel_id)["done"] == ["V001"]
            os.unlink(p.state)
            state, ledger, api, up, log = session(p, plan, fake)
            try:
                up.run(["V001"], fake.channel_id)
                raise AssertionError("uploaded twice")
            except Fatal as e:
                assert "already has a video with this exact title" in str(e)
            assert fake.inserts() == 1
            state, ledger, api, up, log = session(p, plan, fake, adopt=True)
            s = up.run(["V001"], fake.channel_id)
            assert fake.inserts() == 1 and state.d["videos"]["V001"]["video_id"] == "vid001", s
            assert len(fake.playlist_items) == 4, "known limit: adoption re-adds playlist entries"
        finally:
            fake.close()

    @test("resume: a step that failed is retried on the next run without a new upload")
    def _():
        p, plan = sandbox("step", 2)
        fake = FakeYouTube()
        try:
            fake.fail_once["thumbnails.set"] = 403
            state, ledger, api, up, log = session(p, plan, fake)
            s = up.run(["V001", "V002"], fake.channel_id)
            assert s["done"] == ["V002"] and s["pending"] == ["V001"], (s, log)
            assert state.d["videos"]["V001"]["steps"]["thumbnail"]["status"] == "failed"
            assert state.d["videos"]["V001"]["steps"]["captions"]["status"] == "ok"
            state, ledger, api, up, log = session(p, plan, fake)
            s = up.run(["V001", "V002"], fake.channel_id)
            assert s["done"] == ["V001"] and fake.inserts() == 2 and len(fake.captions) == 2
            assert fake.calls["thumbnails.set"] == 3 and len(fake.playlist_items) == 4
        finally:
            fake.close()

    @test("retry: a 503 is retried with backoff; a 401 refreshes the token once")
    def _():
        p, plan = sandbox("retry", 1)
        fake = FakeYouTube()
        try:
            fake.fail_once.update({"captions.insert": 503, "videos.insert": 503, "playlists.insert": 500})
            write_json(p.token, {"refresh_token": "fake-refresh", "access_token": "revoked-early",
                                 "expires_at": time.time() + 3600}, 0o600)   # looks valid, is not
            state, ledger, api, up, log = session(p, plan, fake)
            s = up.run(["V001"], fake.channel_id)
            assert s["done"] == ["V001"], (s, log)
            assert fake.calls["videos.insert"] == 2 and len(fake.sessions) == 1
            assert fake.calls["captions.insert"] == 2 and len(fake.captions) == 1
            assert ledger.today()["uploads"] == 2, "the failed attempt is counted too"
            assert any("temporary error (503)" in str(x) for x in log)
            assert fake.token_refreshes == 1 and fake.calls["channels.list"] == 2, "401, refresh, retry"
        finally:
            fake.close()

    @test("limits: the run stops cleanly when quota for the next video is missing")
    def _():
        p, plan = sandbox("stop", 3)
        fake = FakeYouTube()
        try:
            state, ledger, api, up, log = session(p, plan, fake, daily_units=1400)
            s = up.run(["V001", "V002", "V003"], fake.channel_id)
            assert s["done"] == ["V001", "V002"] and "V003 needs 551 units" in s["stopped"], s
            assert "rerun after" in s["stopped"] and fake.inserts() == 2
            state, ledger, api, up, log = session(p, plan, fake, daily_uploads=2)
            s = up.run(["V003"], fake.channel_id)
            assert s["stopped"] and fake.inserts() == 2, s
            later = lambda: dt.datetime(2029, 12, 2, 12, tzinfo=dt.timezone.utc)   # noqa: E731
            state, ledger, api, up, log = session(p, plan, fake, clock=later, daily_units=1400)
            s = up.run(["V001", "V002", "V003"], fake.channel_id)
            assert s["done"] == ["V003"] and fake.inserts() == 3, s
        finally:
            fake.close()

    @test("safety: wrong channel aborts; past publish times are skipped unless --reschedule")
    def _():
        p, plan = sandbox("safety", 3)
        fake = FakeYouTube()
        try:
            state, ledger, api, up, log = session(p, plan, fake)
            try:
                up.run(["V001"], "UCsomeoneelse")
                raise AssertionError("uploaded to an unconfirmed channel")
            except Fatal:
                pass
            assert fake.inserts() == 0
            late = lambda: dt.datetime(2030, 1, 1, 6, 0, tzinfo=dt.timezone.utc)   # noqa: E731
            # V001 03:30Z is past; V002 08:30Z is still ahead
            state, ledger, api, up, log = session(p, plan, fake, clock=late)
            s = up.run(["V001", "V002"], fake.channel_id)
            assert s["skipped_past"] == ["V001"] and s["done"] == ["V002"], (s, log)
            state, ledger, api, up, log = session(p, plan, fake, clock=late)
            s = up.run(["V001", "V003"], fake.channel_id, reschedule=True)
            assert s["done"] == ["V001", "V003"], (s, log)
            new = {i["id"]: i["publish_at"] for i in read_json(p.plan)["videos"]}
            assert new == {"V001": "2030-01-01T08:30:00Z", "V002": "2030-01-01T08:30:00Z",
                           "V003": "2030-01-01T18:30:00Z"}, new   # V002 was uploaded: it keeps its time
            assert fake.videos[state.d["videos"]["V001"]["video_id"]]["status"]["publishAt"] == new["V001"]
            assert all(parse_rfc3339(v["status"]["publishAt"]) > late() for v in fake.videos.values())
        finally:
            fake.close()

    @test("verify: differences are found; retime changes only the publish time")
    def _():
        p, plan = sandbox("verify", 2)
        fake = FakeYouTube()
        try:
            state, ledger, api, up, log = session(p, plan, fake)
            up.run(["V001", "V002"], fake.channel_id)
            ids = {v: state.d["videos"][v]["video_id"] for v in ("V001", "V002")}
            mem = {"course": set(ids.values()), "part-00": {ids["V001"]}}
            now = dt.datetime(2029, 12, 1, tzinfo=dt.timezone.utc)
            item = {i["id"]: i for i in plan["videos"]}
            assert compare_video(item["V001"], fake.videos[ids["V001"]], plan["settings"], mem, now) == []
            d = compare_video(item["V002"], fake.videos[ids["V002"]], plan["settings"], mem, now)
            assert d == ["playlist: not in part-00"], d
            broken = json.loads(json.dumps(fake.videos[ids["V001"]]))
            broken["snippet"]["title"] = "Other"
            broken["snippet"]["tags"] = ["git"]
            broken["status"]["publishAt"] = "2030-05-05T00:00:00Z"
            broken["contentDetails"].update(caption="false", hasCustomThumbnail=False)
            d = compare_video(item["V001"], broken, plan["settings"], mem, now)
            assert len(d) == 5, d
            after = dt.datetime(2031, 1, 1, tzinfo=dt.timezone.utc)
            d = compare_video(item["V001"], fake.videos[ids["V001"]], plan["settings"], mem, after)
            assert len(d) == 1 and "still private after the publish time" in d[0], d
            api.update_status(ids["V001"], {"privacyStatus": "private", "publishAt": "2030-02-02T02:00:00Z",
                                            "embeddable": True})
            assert fake.videos[ids["V001"]]["status"]["publishAt"] == "2030-02-02T02:00:00Z"
            assert ledger.today()["calls"]["videos.update"] == 1
        finally:
            fake.close()

    @test("dry run: prints every request and makes no call, writes no state")
    def _():
        p, plan = sandbox("dry", 1)
        fake = FakeYouTube()
        try:
            lines = []
            ns = argparse.Namespace(lead_minutes=30, reschedule=False)
            dry_run_upload(p, plan, State(p.state, read_only=True), ["V001"], ns, lines.append)
            text = "\n".join(map(str, lines))
            for needle in ("uploadType=resumable", '"privacyStatus": "private"', '"publishAt": "2030-01-01T03:30:00Z"',
                           "thumbnails/set", "/upload/youtube/v3/captions", "/youtube/v3/playlistItems",
                           "WOULD DOWNLOAD https://github.com/harshaksh-singh/git-github-mastery/releases/"
                           "download/videos-batch-01/V001.mp4"):
                assert needle in text, needle
            assert not fake.calls and not os.path.exists(p.state) and "Bearer" not in text
        finally:
            fake.close()

    @test("report: REPORT.md and report.csv are written from state")
    def _():
        p, plan = sandbox("report", 2)
        fake = FakeYouTube()
        try:
            state, ledger, api, up, log = session(p, plan, fake)
            up.run(["V001"], fake.channel_id)
            cmd_report(p, argparse.Namespace(dry_run=False), out=lambda *_: None)
            md = open(p.report_md).read()
            rows = list(csv.reader(open(p.report_csv)))
            assert "Finished (all five steps ok): 1 of 2" in md and "https://youtu.be/vid001" in md
            assert rows[0][:6] == ["video", "title", "publish_time_Asia/Kolkata", "publish_time_utc", "url", "state"]
            assert rows[1][5] == "done" and rows[2][5] == "not started" and len(rows) == 3
        finally:
            fake.close()

    @test("plan: the real course builds with no violation (offline)")
    def _():
        plan = build_plan(paths, cfg, parse_local_start("2026-10-20 09:00", ist), 5, ist)
        assert len(plan["videos"]) == 201 and len(plan["playlists"]) == 13
        assert plan_violations(plan) == [], plan_violations(plan)[:5]
        v = plan["videos"]
        assert v[0]["publish_at"] == "2026-10-20T03:30:00Z" and v[-1]["publish_at"] == "2026-11-30T19:30:00Z"
        assert v[0]["description"].split("\n")[2] == "0:00 Hook" and v[0]["description"].endswith(REPO_URL)
        assert v[0]["playlists"] == ["course", "part-00"] and v[200]["playlists"] == ["course", "part-11"]
        assert v[133]["asset_url"].endswith("/videos-batch-05/V134.mp4")
        body = insert_body(v[0], plan["settings"])
        assert body["status"] == {"privacyStatus": "private", "publishAt": "2026-10-20T03:30:00Z",
                                  "selfDeclaredMadeForKids": False, "license": "youtube",
                                  "embeddable": True, "publicStatsViewable": True}
        bad = json.loads(json.dumps(cfg))
        bad["link_line"] = "x" * 5000
        bad["base_tags"] = ["t" * 501]
        plan2 = build_plan(paths, bad, parse_local_start("2026-10-20 09:00", ist), 5, ist)
        assert len(plan_violations(plan2)) == 402, "over-long text is reported, never cut"
        assert plan2["videos"][0]["description"].endswith("x" * 5000)

    shutil.rmtree(tmp_root, ignore_errors=True)
    failed = [n for n, e in results if e]
    print(f"\nselftest: {len(results) - len(failed)} of {len(results)} passed")
    return 1 if failed else 0


# --------------------------------------------------------------------------
# Command line
# --------------------------------------------------------------------------

def build_parser():
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--dry-run", action="store_true",
                        help="print what would be sent or written; no API call, nothing written")
    apiopts = argparse.ArgumentParser(add_help=False)
    apiopts.add_argument("--channel-id", help="the channel the videos must go to (UC...)")
    apiopts.add_argument("--daily-units", type=int, default=DEFAULT_DAILY_UNITS,
                         help="daily quota of the project for everything except videos.insert")
    apiopts.add_argument("--daily-uploads", type=int, default=DEFAULT_DAILY_UPLOADS,
                         help="daily videos.insert calls allowed for the project")
    apiopts.add_argument("--reserve-units", type=int, default=DEFAULT_RESERVE_UNITS,
                         help="units kept back for whoami, verify and retries")
    apiopts.add_argument("--lead-minutes", type=int, default=30,
                         help="a publish time closer than this counts as past")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--selftest", action="store_true", help="run the offline tests and exit")
    sub = ap.add_subparsers(dest="cmd")
    p = sub.add_parser("plan", parents=[common], help="build plan.json and PLAN.md")
    p.add_argument("--start", required=True, help='first publish time in Asia/Kolkata, "YYYY-MM-DD HH:MM"')
    p.add_argument("--gap-hours", type=float, default=5.0)
    p.add_argument("--from", dest="from_video", metavar="VNNN",
                   help="keep the times of earlier videos; --start is the time of this video")
    p = sub.add_parser("check", parents=[common], help="offline preflight for all videos")
    p.add_argument("--no-network", action="store_true", help="skip the HEAD requests to GitHub")
    sub.add_parser("auth", parents=[common], help="sign in with Google (opens the browser)")
    p = sub.add_parser("whoami", parents=[common, apiopts], help="show the channel of the token")
    p.add_argument("--confirm", action="store_true", help="store this channel as the confirmed one")
    p = sub.add_parser("upload", parents=[common, apiopts], help="upload and schedule videos")
    g = p.add_mutually_exclusive_group()
    g.add_argument("--only", nargs="+", metavar="VNNN")
    g.add_argument("--next", type=int, metavar="N")
    g.add_argument("--all", action="store_true")
    p.add_argument("--reschedule", action="store_true",
                   help="move not-yet-uploaded videos later when their time has passed")
    p.add_argument("--adopt", action="store_true",
                   help="record an existing channel video with the same title instead of stopping")
    p.add_argument("--chunk-mb", type=float, default=0,
                   help="send the file in pieces of this size (multiple of 0.25); default one request")
    p.add_argument("--verify-wait", type=int, default=120,
                   help="seconds to wait for YouTube processing before moving on")
    p = sub.add_parser("verify", parents=[common, apiopts], help="compare YouTube with the plan")
    p = sub.add_parser("retime", parents=[common, apiopts],
                       help="apply changed publish times to uploaded, still private videos")
    p.add_argument("--only", nargs="+", metavar="VNNN")
    sub.add_parser("status", parents=[common], help="same as report")
    sub.add_parser("report", parents=[common], help="write REPORT.md and report.csv")
    return ap


def main(argv=None):
    ap = build_parser()
    args = ap.parse_args(argv)
    paths = Paths()
    try:
        if args.selftest:
            return selftest(paths)
        if not args.cmd:
            ap.print_help()
            return 2
        if args.cmd == "auth":
            return run_auth(paths, dry_run=args.dry_run)
        fn = {"plan": cmd_plan, "check": cmd_check, "whoami": cmd_whoami, "upload": cmd_upload,
              "verify": cmd_verify, "retime": cmd_retime, "status": cmd_report, "report": cmd_report}[args.cmd]
        return fn(paths, args)
    except Fatal as e:
        print("ERROR: " + str(e), file=sys.stderr)
        return 2
    except StopRun as e:
        print("STOPPED: " + str(e))
        return 0
    except HttpError as e:
        print(f"ERROR from the API: {e}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("\nInterrupted. State is saved after every step; run the same command again to continue.")
        return 130


if __name__ == "__main__":
    sys.exit(main())
