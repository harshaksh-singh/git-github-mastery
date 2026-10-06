#!/usr/bin/env python3
"""Recording takes: turn the booth's key-press log into "keep this stretch of audio for beat N".

The booth records one continuous audio file per take and logs events, each with its time in seconds on that file:

    begin    {beat}          the take of a beat starts
    advance  {beat, next}    the beat is finished and kept; the next beat starts at the same instant
    retake   {beat}          what was said since the beat started is thrown away; the beat starts again
    goto     {beat}          jump back to an earlier beat; the unfinished beat is thrown away
    pause    {beat}          the unfinished beat is thrown away; nothing is kept until "resume"
    resume   {beat}          the beat starts again
    finish   {beat}          the take ends; the beat in progress is kept (unless the booth was paused)

Everything that is not inside a kept stretch is cut by the builder.  If a beat is recorded more than once
(in the same take or in a later take), the newest recording wins.
"""
import json, sys

sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parent))
from video_common import *   # noqa: F401,F403


def segments_from_events(events):
    """-> (segments sorted by beat: [{"beat", "start", "end"}], number of discarded stretches)"""
    kept, cur, discarded = [], None, 0
    for e in events:
        t, ty = float(e["t"]), e["type"]
        if ty in ("begin", "resume", "goto"):
            if cur is not None and ty == "goto" and t > cur[1]:
                discarded += 1
            cur = (int(e["beat"]), t)
        elif ty == "advance":
            if cur is not None and cur[0] == int(e["beat"]) and t > cur[1]:
                kept.append({"beat": cur[0], "start": cur[1], "end": t})
            cur = (int(e.get("next", int(e["beat"]) + 1)), t)
        elif ty == "retake":
            discarded += 1
            cur = (int(e["beat"]), t)
        elif ty == "pause":
            if cur is not None and t > cur[1]:
                discarded += 1
            cur = None
        elif ty == "finish":
            if cur is not None and e.get("complete", True) and t > cur[1]:
                kept.append({"beat": cur[0], "start": cur[1], "end": t})
            cur = None
    final = {}
    for s in kept:                     # a later recording of the same beat replaces the earlier one
        if s["beat"] in final:
            discarded += 1
        final[s["beat"]] = s
    return [final[k] for k in sorted(final)], discarded


def timing_path(vid):
    return RECORDINGS / f"{vid}.timing.json"


def load_timing(vid):
    p = timing_path(vid)
    if not p.exists():
        return None
    return json.loads(p.read_text(encoding="utf-8"))


def resolve(sb, timing):
    """Which audio stretch does each beat use?  -> (dict beat -> (file, start, end), stale beats, missing narration beats)"""
    beats = sb["beats"]
    use, stale = {}, set()
    for take in (timing or {}).get("takes", []):
        hashes = take.get("beat_hashes") or []
        segs = take.get("segments")
        if segs is None:
            segs, _ = segments_from_events(take.get("events", []))
        for s in segs:
            i = s["beat"]
            if i >= len(beats) or s["end"] <= s["start"]:
                continue
            if i < len(hashes) and hashes[i] != beats[i]["h"]:
                stale.add(i); use.pop(i, None)       # the script changed under this beat: it must be read again
                continue
            stale.discard(i)
            use[i] = (take["file"], float(s["start"]), float(s["end"]))
    missing = [b["i"] for b in beats if b["type"] == "narration" and b["i"] not in use]
    return use, sorted(stale), missing
